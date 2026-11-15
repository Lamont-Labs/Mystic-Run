using System;
using MysticRun.UnityEvaluation;

static class Program
{
    static int checks;
    static void Check(bool ok, string message)
    {
        checks++;
        if (!ok) throw new Exception(message);
    }
    static void Main()
    {
        var input = new RunnerIntent();
        Check(input.Lane == 0, "Start in center");
        for (int i = 0; i < 10; i++) input.ChangeLane(1);
        Check(input.Lane == 1, "Clamp right edge");
        for (int i = 0; i < 20; i++) input.ChangeLane(-1);
        Check(input.Lane == -1, "Clamp left edge");
        input.ChangeLane(1); Check(input.Lane == 0, "Retarget immediately");
        input.Request(VerticalIntent.Jump, 1);
        input.Request(VerticalIntent.Slide, 1.01);
        Check(input.Consume(1.02, true, true) == VerticalIntent.Slide, "Latest down wins");
        Check(input.Consume(1.03, true, true) == VerticalIntent.None, "No stale jump after slide");
        input.Request(VerticalIntent.Slide, 2);
        input.Request(VerticalIntent.Jump, 2.01);
        Check(input.Consume(2.02, true, true) == VerticalIntent.Jump, "Latest up wins");
        Check(input.Consume(2.03, true, true) == VerticalIntent.None, "No stale slide after jump");
        input.Request(VerticalIntent.Jump, 3);
        Check(input.Consume(3.05, false, false) == VerticalIntent.None, "Buffer until permitted");
        Check(input.Consume(3.10, true, true) == VerticalIntent.Jump, "Consume on landing");
        input.Request(VerticalIntent.Jump, 4);
        Check(input.Consume(4.15, true, true) == VerticalIntent.None, "Expired input does not fire later");
        input.Request(VerticalIntent.Slide, 5);
        Check(input.Consume(5.01, true, false) == VerticalIntent.None, "Do not slide airborne");
        Check(input.Consume(5.02, false, true) == VerticalIntent.Slide, "Slide when allowed");
        input.Request(VerticalIntent.Jump, 6);
        input.Clear();
        Check(input.Pending == VerticalIntent.None, "Focus loss cancels buffered intent");
        foreach (double bad in new[] { double.NaN, double.PositiveInfinity, double.NegativeInfinity })
        {
            bool rejected = false;
            try { input.Request(VerticalIntent.Jump, bad); }
            catch (ArgumentOutOfRangeException) { rejected = true; }
            Check(rejected, "Reject invalid clock");
        }
        bool invalidDirection = false;
        try { input.ChangeLane(0); } catch (ArgumentOutOfRangeException) { invalidDirection = true; }
        Check(invalidDirection, "Reject unsupported direction");
        Console.WriteLine($"UNITY_PORTABLE_INTENT: {checks}/{checks} passed. NOT Unity Editor, physics, rendering or Android tests.");
    }
}
