using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.EnhancedTouch;
using Touch = UnityEngine.InputSystem.EnhancedTouch.Touch;

namespace MysticRun.UnityEvaluation
{
    [DefaultExecutionOrder(-50)]
    [RequireComponent(typeof(RunnerMotor))]
    public sealed class RunnerInput : MonoBehaviour
    {
        RunnerMotor motor;
        int activeFinger = -1;
        Vector2 origin;

        void Awake() { motor = GetComponent<RunnerMotor>(); }
        void OnEnable()
        {
            EnhancedTouchSupport.Enable();
            Touch.onFingerDown += Begin;
            Touch.onFingerUp += End;
        }
        void OnDisable()
        {
            Touch.onFingerDown -= Begin;
            Touch.onFingerUp -= End;
            EnhancedTouchSupport.Disable();
            activeFinger = -1;
            if (motor != null) motor.Intent.Clear();
        }
        void OnApplicationFocus(bool focused)
        {
            if (!focused) { activeFinger = -1; motor.Intent.Clear(); }
        }
        void Begin(Finger finger)
        {
            if (activeFinger >= 0) return;
            activeFinger = finger.index;
            origin = finger.currentTouch.screenPosition;
        }
        void End(Finger finger)
        {
            if (finger.index != activeFinger) return;
            activeFinger = -1;
            if (finger.currentTouch.phase == UnityEngine.InputSystem.TouchPhase.Canceled)
                return;
            var delta = finger.currentTouch.screenPosition - origin;
            if (delta.magnitude < Mathf.Min(Screen.width, Screen.height) * 0.07f)
                return;
            // Exact diagonal ties resolve vertically rather than disappearing.
            if (Mathf.Abs(delta.y) >= Mathf.Abs(delta.x))
                motor.Intent.Request(delta.y > 0 ? VerticalIntent.Jump : VerticalIntent.Slide, Time.timeAsDouble);
            else motor.Intent.ChangeLane(delta.x > 0 ? 1 : -1);
        }
        void Update()
        {
            var keys = Keyboard.current;
            if (keys == null) return;
            if (keys.leftArrowKey.wasPressedThisFrame || keys.aKey.wasPressedThisFrame)
                motor.Intent.ChangeLane(-1);
            if (keys.rightArrowKey.wasPressedThisFrame || keys.dKey.wasPressedThisFrame)
                motor.Intent.ChangeLane(1);
            if (keys.upArrowKey.wasPressedThisFrame || keys.spaceKey.wasPressedThisFrame)
                motor.Intent.Request(VerticalIntent.Jump, Time.timeAsDouble);
            if (keys.downArrowKey.wasPressedThisFrame || keys.sKey.wasPressedThisFrame)
                motor.Intent.Request(VerticalIntent.Slide, Time.timeAsDouble);
        }
    }
}
