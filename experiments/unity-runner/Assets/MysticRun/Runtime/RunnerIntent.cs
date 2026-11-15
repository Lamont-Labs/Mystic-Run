using System;

namespace MysticRun.UnityEvaluation
{
    public enum VerticalIntent { None, Jump, Slide }

    // Portable input contract only. Collision, damping and camera use Unity.
    public sealed class RunnerIntent
    {
        public int Lane { get; private set; }
        public VerticalIntent Pending { get; private set; }
        public double ExpiresAt { get; private set; } = double.NegativeInfinity;
        public const double BufferSeconds = 0.14;

        public void ChangeLane(int direction)
        {
            if (direction != -1 && direction != 1)
                throw new ArgumentOutOfRangeException(nameof(direction));
            Lane = Math.Max(-1, Math.Min(1, Lane + direction));
        }

        public void Request(VerticalIntent intent, double now)
        {
            if (intent != VerticalIntent.Jump && intent != VerticalIntent.Slide)
                throw new ArgumentOutOfRangeException(nameof(intent));
            if (double.IsNaN(now) || double.IsInfinity(now))
                throw new ArgumentOutOfRangeException(nameof(now));
            Pending = intent; // Most recent intent replaces its opposite.
            ExpiresAt = now + BufferSeconds;
        }

        public VerticalIntent Consume(double now, bool canJump, bool canSlide)
        {
            if (now > ExpiresAt) Clear();
            var result = Pending;
            if ((result == VerticalIntent.Jump && canJump) ||
                (result == VerticalIntent.Slide && canSlide))
            {
                Clear();
                return result;
            }
            return VerticalIntent.None;
        }

        public void Clear()
        {
            Pending = VerticalIntent.None;
            ExpiresAt = double.NegativeInfinity;
        }
    }
}
