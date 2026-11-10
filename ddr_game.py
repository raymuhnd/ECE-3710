"""
Run:   python ddr_game.py          # Play using Tkinter and the arrow keys.
       python ddr_game.py --demo   # Deterministic example, no window needed.
       python ddr_game.py --test   # Check timing, scoring, and state transitions.

This MVP uses tap notes and binary HIT/MISS scoring. The included practice
chart has no music. Edit SONG_CHART to change the notes. Times are integer
milliseconds from the start of play; the first note includes a lead-in.

Hardware mapping:
  SONG_CHART       -> BRAM pairs: (time_ms, direction)
  elapsed_ms       -> hardware game timer
  press()          -> new PS/2 key-down event, excluding typematic repeats
  update()         -> called continuously by the CPU's polling loop
  status/score     -> VGA note visibility and score display

DDRGame is independent of the keyboard, wall clock, and display. The Python
classes are for readability; assembly can use arrays and integer variables.
"""

import argparse
from dataclasses import dataclass
from time import monotonic_ns


# Simple numeric direction codes that can also be stored in BRAM.
LEFT, DOWN, UP, RIGHT = range(4)
LANE_NAMES = ("LEFT", "DOWN", "UP", "RIGHT")
HIT_WINDOW_MS = 150
POINTS_PER_HIT = 100

# Each pair is (target time in milliseconds, direction).
# A simultaneous pair in different lanes is allowed; hold notes are not used.
SONG_CHART = (
    (2000, LEFT), (2500, DOWN), (3000, UP), (3500, RIGHT),
    (4000, LEFT), (4500, UP), (5000, DOWN), (5500, RIGHT),
    (6000, LEFT), (6500, DOWN), (7000, LEFT), (7500, UP),
    (8000, RIGHT), (8500, UP), (9000, RIGHT), (9500, DOWN),
    (10000, LEFT), (10500, RIGHT), (11000, DOWN), (11500, UP),
    (12000, LEFT), (12500, DOWN), (13000, UP), (13500, RIGHT),
    (14000, LEFT), (14500, RIGHT), (15000, UP), (15500, DOWN),
    (16000, LEFT), (16500, DOWN), (17000, UP), (17500, RIGHT),
)


@dataclass(frozen=True)
class Judgment:
    kind: str                 # "HIT" or "MISS"
    note_index: int
    offset_ms: int             # Negative = early, positive = late.


class DDRGame:
    """The game logic: chart, per-note state, timing, and scoring.

    Call start(), then update(elapsed_ms) every loop and press(lane,
    elapsed_ms) for each NEW key press. Both return judgments for feedback.
    All timestamps in a round must be nonnegative and nondecreasing.

    Policy: each press hits the earliest unresolved note in that lane if it
    is within the inclusive +/- hit window. A note can score only once.
    Unmatched presses do nothing. Only an overdue note counts as a miss.
    """

    def __init__(self, chart=SONG_CHART, hit_window_ms=HIT_WINDOW_MS):
        if type(hit_window_ms) is not int or hit_window_ms < 0:
            raise ValueError("Hit window must be a nonnegative integer.")
        notes = []
        for time_ms, lane in chart:
            if type(time_ms) is not int or time_ms < 0:
                raise ValueError("Note times must be nonnegative integers.")
            if type(lane) is not int or lane not in range(4):
                raise ValueError("Note direction must be LEFT, DOWN, UP, or RIGHT.")
            notes.append((time_ms, lane))
        if len(set(notes)) != len(notes):
            raise ValueError("Duplicate notes in the same lane and time are invalid.")
        self.chart = tuple(sorted(notes))
        self.hit_window_ms = hit_window_ms
        self.reset()

    def reset(self):
        self.status = ["PENDING"] * len(self.chart)
        self.state = "READY"
        self.score = self.hits = self.misses = 0
        self.combo = self.max_combo = 0
        self.elapsed_ms = 0
        self.remaining = len(self.chart)
        self.expire_index = 0

    def start(self):
        """Start a fresh round, including when restarting a completed one."""
        self.reset()
        self.state = "PLAYING" if self.chart else "FINISHED"

    def update(self, elapsed_ms):
        """Mark every overdue note as missed, even if a frame was delayed."""
        if type(elapsed_ms) is not int or elapsed_ms < self.elapsed_ms:
            raise ValueError("Time must be a nondecreasing integer in milliseconds.")
        if self.state != "PLAYING":
            return []
        self.elapsed_ms = elapsed_ms
        judgments = []

        # Chart is time-sorted, so notes before this pointer never need
        # another expiry check. Equality is still a legal last-moment hit.
        while self.expire_index < len(self.chart):
            i = self.expire_index
            note_ms, _ = self.chart[i]
            if elapsed_ms <= note_ms + self.hit_window_ms:
                break
            if self.status[i] == "PENDING":
                self.status[i] = "MISS"
                self.misses += 1
                self.remaining -= 1
                self.combo = 0
                judgments.append(Judgment("MISS", i, elapsed_ms - note_ms))
            self.expire_index += 1

        if self.remaining == 0:
            self.state = "FINISHED"
        return judgments

    def press(self, lane, elapsed_ms):
        """Process missed notes first, then at most one hit for this press."""
        if type(lane) is not int or lane not in range(4):
            raise ValueError("Unknown direction.")
        judgments = self.update(elapsed_ms)
        if self.state != "PLAYING":
            return judgments

        for i in range(self.expire_index, len(self.chart)):
            note_ms, note_lane = self.chart[i]
            if note_ms > elapsed_ms + self.hit_window_ms:
                break
            if note_lane == lane and self.status[i] == "PENDING":
                self.status[i] = "HIT"
                self.hits += 1
                self.remaining -= 1
                self.score += POINTS_PER_HIT
                self.combo += 1
                self.max_combo = max(self.max_combo, self.combo)
                judgments.append(Judgment("HIT", i, elapsed_ms - note_ms))
                if self.remaining == 0:
                    self.state = "FINISHED"
                break
        return judgments


def run_window():
    """Small display/input adapter. No third-party Python packages needed."""
    try:
        import tkinter as tk
    except ImportError as exc:
        raise SystemExit("Tkinter is required for the window. Try --demo or --test.") from exc
    try:
        root = tk.Tk()
    except tk.TclError as exc:
        raise SystemExit("Cannot open a desktop window. Try --demo or --test.") from exc

    root.title("CRISC16 DDR prototype")
    root.resizable(False, False)
    canvas = tk.Canvas(root, width=600, height=660, bg="#101827", highlightthickness=0)
    canvas.pack()
    game = DDRGame()
    keys = {"Left": LEFT, "Down": DOWN, "Up": UP, "Right": RIGHT}
    symbols = ("\u2190", "\u2193", "\u2191", "\u2192")
    colors = ("#71d5ff", "#ffbf69", "#9df0b2", "#d3adff")
    held = set()
    releases = {}
    start_ns = 0
    feedback = "Press SPACE to start"
    feedback_until = 0
    target_y = 180
    travel_ms = 1800

    def clock_ms():
        return (monotonic_ns() - start_ns) // 1_000_000

    def show_judgments(judgments, now):
        nonlocal feedback, feedback_until
        if judgments:
            j = judgments[-1]
            feedback = j.kind
            if j.kind == "HIT":
                feedback += f"  {j.offset_ms:+d} ms"
            feedback_until = now + 600

    def key_down(event):
        nonlocal start_ns, feedback, feedback_until
        key = event.keysym
        # Some desktops emit release/press pairs during auto-repeat. Cancel
        # the deferred release so holding an arrow cannot score more notes.
        if key in releases:
            root.after_cancel(releases.pop(key))
        if key in held:
            return
        held.add(key)
        if key in ("space", "r", "R"):
            game.start()
            start_ns = monotonic_ns()
            feedback, feedback_until = "Get ready!", 1200
        elif key == "Escape":
            root.destroy()
        elif key in keys and game.state == "PLAYING":
            now = clock_ms()
            show_judgments(game.press(keys[key], now), now)

    def key_up(event):
        key = event.keysym

        def release():
            held.discard(key)
            releases.pop(key, None)

        if key not in releases:
            releases[key] = root.after_idle(release)

    def lose_focus(_event):
        for job in releases.values():
            root.after_cancel(job)
        releases.clear()
        held.clear()

    def draw():
        now = clock_ms() if game.state == "PLAYING" else game.elapsed_ms
        show_judgments(game.update(now), now)
        canvas.delete("all")
        canvas.create_text(300, 30, text="CRISC16 / DDR", fill="white", font=("Arial", 22, "bold"))
        canvas.create_text(300, 65, text=f"Score {game.score}    Combo {game.combo}    Best {game.max_combo}", fill="white", font=("Arial", 14))
        canvas.create_text(300, 95, text=f"Hits {game.hits}    Misses {game.misses}    Notes left {game.remaining}", fill="#b0bfd2", font=("Arial", 12))
        canvas.create_line(70, target_y, 530, target_y, fill="#53647c", width=2)
        for lane in range(4):
            x = 120 + lane * 120
            canvas.create_line(x, target_y + 45, x, 575, fill="#243249")
            active = tuple(keys)[lane] in held
            canvas.create_rectangle(x-38, target_y-35, x+38, target_y+35, outline=colors[lane], width=4 if active else 1)
            canvas.create_text(x, target_y, text=symbols[lane], fill=colors[lane], font=("Arial", 36))
        if game.state == "PLAYING":
            for i, (note_ms, lane) in enumerate(game.chart):
                until = note_ms - now
                if game.status[i] == "PENDING" and -game.hit_window_ms <= until <= travel_ms:
                    x = 120 + lane * 120
                    y = target_y + until * 390 / travel_ms
                    canvas.create_rectangle(x-29, y-25, x+29, y+25, fill=colors[lane], outline="")
                    canvas.create_text(x, y, text=symbols[lane], fill="#101827", font=("Arial", 30, "bold"))
        if game.state == "FINISHED":
            accuracy = 100 * game.hits / len(game.chart) if game.chart else 0
            canvas.create_text(300, 350, text=f"Finished!  {accuracy:.1f}% notes hit\nPress SPACE to play again", fill="white", font=("Arial", 18), justify="center")
        elif game.state == "READY" or now <= feedback_until:
            canvas.create_text(300, 125, text=feedback, fill="white", font=("Arial", 13, "bold"))
        canvas.create_text(300, 610, text="Arrow keys: hit notes    SPACE / R: restart    ESC: quit", fill="#b0bfd2", font=("Arial", 11))
        canvas.create_text(300, 638, text="Practice chart • No music • Hit window: ±150 ms", fill="#b0bfd2", font=("Arial", 11))
        root.after(16, draw)

    root.bind("<KeyPress>", key_down)
    root.bind("<KeyRelease>", key_up)
    root.bind("<FocusOut>", lose_focus)
    root.after_idle(root.focus_force)
    draw()
    root.mainloop()


def run_demo():
    game = DDRGame(((1000, LEFT), (1500, DOWN), (2000, UP), (2500, RIGHT)))
    game.start()
    for lane, now in ((LEFT, 950), (DOWN, 1600), (RIGHT, 2500)):
        for result in game.press(lane, now):
            print(f"Note {result.note_index}: {result.kind} ({result.offset_ms:+d} ms)")
    print(f"{game.state}: score={game.score}, hits={game.hits}, "
          f"misses={game.misses}, max_combo={game.max_combo}")


def run_tests():
    """Small regression suite for the rules that matter when porting to CPU."""
    import unittest

    class GameTests(unittest.TestCase):
        def game(self, chart=((1000, LEFT),)):
            game = DDRGame(chart)
            game.start()
            return game

        def test_inclusive_boundaries(self):
            for now in (850, 1000, 1150):
                with self.subTest(now=now):
                    game = self.game()
                    self.assertEqual(game.press(LEFT, now)[0].kind, "HIT")
                    self.assertEqual(game.score, 100)

        def test_early_and_wrong_lane_do_not_consume_note(self):
            game = self.game()
            self.assertEqual(game.press(LEFT, 849), [])
            self.assertEqual(game.press(RIGHT, 1000), [])
            self.assertEqual(game.press(LEFT, 1000)[0].kind, "HIT")

        def test_late_press_is_miss(self):
            game = self.game()
            self.assertEqual(game.press(LEFT, 1151)[0].kind, "MISS")
            self.assertEqual((game.score, game.misses, game.state), (0, 1, "FINISHED"))

        def test_no_double_scoring(self):
            game = self.game(((1000, LEFT), (2000, RIGHT)))
            game.press(LEFT, 1000)
            self.assertEqual(game.press(LEFT, 1000), [])
            self.assertEqual((game.score, game.hits), (100, 1))

        def test_delayed_frame_expires_all_notes(self):
            game = self.game(((1000, LEFT), (1500, DOWN), (2000, UP)))
            self.assertEqual(len(game.update(3000)), 3)
            self.assertEqual((game.misses, game.remaining, game.state), (3, 0, "FINISHED"))
            self.assertEqual(game.update(3000), [])

        def test_combo_resets_before_next_hit(self):
            game = self.game(((1000, LEFT), (1500, DOWN), (2000, UP), (2500, RIGHT)))
            game.press(LEFT, 1000)
            game.press(DOWN, 1500)
            judgments = game.press(RIGHT, 2500)
            self.assertEqual([j.kind for j in judgments], ["MISS", "HIT"])
            self.assertEqual((game.combo, game.max_combo, game.score), (1, 2, 300))

        def test_one_press_one_note_and_chords(self):
            game = self.game(((1000, LEFT), (1100, LEFT), (1100, RIGHT)))
            self.assertEqual(game.press(LEFT, 1050)[0].note_index, 0)
            self.assertEqual(game.hits, 1)
            game.press(LEFT, 1100)
            game.press(RIGHT, 1100)
            self.assertEqual((game.hits, game.state), (3, "FINISHED"))

        def test_restart_clears_round(self):
            game = self.game()
            game.press(LEFT, 1000)
            game.start()
            self.assertEqual((game.score, game.hits, game.elapsed_ms, game.remaining), (0, 0, 0, 1))
            self.assertEqual(game.status, ["PENDING"])

        def test_empty_chart_and_ready_state(self):
            self.assertEqual(self.game(()).state, "FINISHED")
            game = DDRGame()
            self.assertEqual(game.press(LEFT, 2000), [])
            self.assertEqual(game.state, "READY")

        def test_invalid_chart_and_backwards_clock(self):
            for chart in (((-1, LEFT),), ((0, 4),), ((1000, LEFT), (1000, LEFT))):
                with self.subTest(chart=chart):
                    with self.assertRaises(ValueError):
                        DDRGame(chart)
            game = self.game()
            game.update(900)
            with self.assertRaises(ValueError):
                game.update(899)

        def test_full_chart_perfect_and_all_missed(self):
            game = self.game(SONG_CHART)
            for now, lane in game.chart:
                game.press(lane, now)
            self.assertEqual((game.score, game.hits, game.max_combo), (3200, 32, 32))
            self.assertEqual(game.state, "FINISHED")
            game.start()
            game.update(20000)
            self.assertEqual((game.hits, game.misses, game.remaining), (0, 32, 0))

    result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(GameTests))
    raise SystemExit(0 if result.wasSuccessful() else 1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--demo", action="store_true", help="Run a scripted round without a window")
    mode.add_argument("--test", action="store_true", help="Run the game-logic tests")
    args = parser.parse_args()
    if args.test:
        run_tests()
    elif args.demo:
        run_demo()
    else:
        run_window()
