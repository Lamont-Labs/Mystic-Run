using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;

namespace MysticRun.UnityEvaluation.Editor
{
    public sealed class BlockAndroidBuild : IPreprocessBuildWithReport
    {
        public int callbackOrder => -10000;
        public void OnPreprocessBuild(BuildReport report)
        {
            if (report.summary.platform == BuildTarget.Android)
                throw new BuildFailedException(
                    "Android builds are intentionally locked for this unverified experiment. " +
                    "A future owner-approved integration must use the existing trusted GitHub " +
                    "release pipeline, original package/certificate, increasing version code " +
                    "and an explicit Godot-save migration. Never use an automatic debug key.");
        }
    }
}
