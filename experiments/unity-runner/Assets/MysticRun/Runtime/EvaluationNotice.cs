using UnityEngine;

namespace MysticRun.UnityEvaluation
{
    public sealed class EvaluationNotice : MonoBehaviour
    {
        void OnGUI()
        {
            GUI.Box(new Rect(12, 12, Mathf.Min(Screen.width - 24, 600), 98),
                "UNITY ENGINE EVALUATION — NOT A RELEASE\n" +
                "Static approved reference art; Unity animation authoring pending.\n" +
                "Arrows / A,D: lanes · Space: jump · Down: slide · Touch: swipes\n" +
                "No game saves, signing keys or production data are used.");
        }
    }
}
