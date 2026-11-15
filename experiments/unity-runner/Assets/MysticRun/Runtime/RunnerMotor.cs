using UnityEngine;

namespace MysticRun.UnityEvaluation
{
    [RequireComponent(typeof(CharacterController))]
    public sealed class RunnerMotor : MonoBehaviour
    {
        public RunnerIntent Intent { get; } = new RunnerIntent();
        public Animator AnimationTarget;
        public float ForwardSpeed = 8f;
        public float LaneWidth = 1.65f;
        public bool IsSliding { get; private set; }
        readonly Collider[] clearance = new Collider[16];
        CharacterController body;
        float laneVelocity, verticalSpeed;
        double lastGrounded = double.NegativeInfinity;
        double slideUntil;
        const float StandingHeight = 1.9f;
        const float SlidingHeight = 0.95f;
        const float Gravity = -25f;

        void Awake()
        {
            body = GetComponent<CharacterController>();
            body.height = StandingHeight;
            body.radius = .28f;
            body.center = Vector3.up * StandingHeight * .5f;
            body.skinWidth = .025f;
            body.minMoveDistance = 0f;
            body.stepOffset = .25f;
        }

        bool CanStand()
        {
            var bottom = transform.position + Vector3.up * (body.radius + .035f);
            var top = transform.position + Vector3.up * (StandingHeight - body.radius);
            int count = Physics.OverlapCapsuleNonAlloc(bottom, top, body.radius,
                clearance, ~0, QueryTriggerInteraction.Ignore);
            if (count == clearance.Length) return false; // Fail closed on overflow.
            for (int i = 0; i < count; i++)
                if (clearance[i] != body && !clearance[i].transform.IsChildOf(transform))
                    return false;
            return true;
        }

        void Update()
        {
            float dt = Time.deltaTime;
            if (dt <= 0) return;
            double now = Time.timeAsDouble;
            bool grounded = body.isGrounded;
            if (grounded) lastGrounded = now;
            bool room = CanStand();
            var request = Intent.Consume(now,
                room && (grounded || now - lastGrounded <= .10),
                grounded);
            if (request == VerticalIntent.Jump)
            {
                slideUntil = 0;
                IsSliding = false;
                lastGrounded = double.NegativeInfinity; // No repeated coyote jumps.
                verticalSpeed = Mathf.Sqrt(-2f * Gravity * 1.5f);
            }
            else if (request == VerticalIntent.Slide) slideUntil = now + .65;
            IsSliding = now < slideUntil || (!room && IsSliding);
            float height = IsSliding ? SlidingHeight : StandingHeight;
            body.height = height;
            body.center = Vector3.up * height * .5f; // Feet do not move on resize.
            if (grounded && verticalSpeed < 0) verticalSpeed = -2f;
            verticalSpeed += Gravity * dt;
            float x = Mathf.SmoothDamp(transform.position.x, Intent.Lane * LaneWidth,
                ref laneVelocity, .09f, 18f, dt);
            var flags = body.Move(new Vector3(x - transform.position.x,
                verticalSpeed * dt, ForwardSpeed * dt));
            if ((flags & CollisionFlags.Above) != 0 && verticalSpeed > 0)
                verticalSpeed = 0;
            if ((flags & CollisionFlags.Below) != 0 && verticalSpeed < 0)
                verticalSpeed = -2f;
            if (AnimationTarget != null)
            {
                AnimationTarget.SetFloat("Speed", ForwardSpeed, .08f, dt);
                AnimationTarget.SetFloat("VerticalSpeed", verticalSpeed, .06f, dt);
                AnimationTarget.SetBool("Grounded", body.isGrounded);
                AnimationTarget.SetBool("Sliding", IsSliding);
            }
        }
    }
}
