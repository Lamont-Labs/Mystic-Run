using UnityEngine;

namespace MysticRun.UnityEvaluation
{
    // Reference image only. This is deliberately NOT the rejected cutout rig.
    public sealed class ReferenceBillboard : MonoBehaviour
    {
        void LateUpdate()
        {
            if (Camera.main != null) transform.rotation = Camera.main.transform.rotation;
        }
    }
}
