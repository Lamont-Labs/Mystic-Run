using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using Unity.Cinemachine;

namespace MysticRun.UnityEvaluation.Editor
{
    public static class PrepareEvaluation
    {
        const string Art = "Assets/MysticRun/Art/";
        const string Scene = "Assets/MysticRun/Scenes/RunnerEvaluation.unity";

        [MenuItem("MysticRun/Prepare Engine Evaluation Scene")]
        public static void Create()
        {
            if (!Application.isBatchMode && !EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())
                return;
            if (!File.Exists(Art + "knight_rear.png"))
                throw new System.InvalidOperationException("Run tools/prepare_unity_evaluation.py first.");
            foreach (var name in new[] { "knight_rear.png" })
            {
                var importer = (TextureImporter)AssetImporter.GetAtPath(Art + name);
                importer.textureType = TextureImporterType.Sprite;
                importer.spriteImportMode = SpriteImportMode.Single;
                importer.spritePixelsPerUnit = 170;
                importer.alphaIsTransparency = true;
                importer.SaveAndReimport();
            }
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            PlayerSettings.companyName = "Lamont Labs";
            PlayerSettings.productName = "MysticRun Engine Evaluation";
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android,
                "com.lamontlabs.knightgargoylewitch.dev");

            var runner = new GameObject("Knight — static reference, rig pending");
            runner.AddComponent<CharacterController>();
            runner.AddComponent<RunnerMotor>();
            runner.AddComponent<RunnerInput>();
            var art = new GameObject("Approved rear painting — NOT animated");
            art.transform.SetParent(runner.transform);
            art.transform.localPosition = Vector3.up * 1.04f;
            art.AddComponent<SpriteRenderer>().sprite = AssetDatabase.LoadAssetAtPath<Sprite>(Art + "knight_rear.png");
            art.AddComponent<ReferenceBillboard>();

            var camera = new GameObject("Main Camera");
            camera.tag = "MainCamera";
            camera.AddComponent<Camera>().fieldOfView = 62;
            camera.AddComponent<AudioListener>();
            camera.AddComponent<CinemachineBrain>();
            var follow = new GameObject("Native Cinemachine follow camera");
            follow.transform.rotation = Quaternion.Euler(18, 0, 0);
            follow.AddComponent<CinemachineCamera>().Follow = runner.transform;
            follow.AddComponent<CinemachineFollow>().FollowOffset = new Vector3(0, 3.5f, -7);

            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Collision evaluation surface — not final level art";
            ground.transform.position = new Vector3(0, 0, 150);
            ground.transform.localScale = new Vector3(.85f, 1, 32);
            var material = new Material(Shader.Find("Unlit/Texture"));
            material.mainTexture = AssetDatabase.LoadAssetAtPath<Texture2D>(Art + "castle_stone.jpg");
            material.mainTextureScale = new Vector2(3, 100);
            Directory.CreateDirectory("Assets/MysticRun/Generated");
            AssetDatabase.CreateAsset(material, AssetDatabase.GenerateUniqueAssetPath("Assets/MysticRun/Generated/Stone.mat"));
            ground.GetComponent<Renderer>().sharedMaterial = material;

            // These are explicitly test fixtures, not newly claimed premium art.
            Fixture("Jump collision fixture", new Vector3(0, .4f, 12), new Vector3(1.35f, .8f, .35f), material);
            Fixture("Slide clearance fixture", new Vector3(0, 1.5f, 24), new Vector3(1.35f, .5f, .35f), material);
            new GameObject("Evaluation status").AddComponent<EvaluationNotice>();
            Directory.CreateDirectory(Path.GetDirectoryName(Scene));
            EditorSceneManager.SaveScene(EditorSceneManager.GetActiveScene(), Scene);
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(Scene, true) };
            AssetDatabase.SaveAssets();
            Debug.Log("Unity evaluation source scene prepared. No animation quality or Android compatibility verified.");
        }

        static void Fixture(string name, Vector3 at, Vector3 size, Material material)
        {
            var item = GameObject.CreatePrimitive(PrimitiveType.Cube);
            item.name = name; item.transform.position = at; item.transform.localScale = size;
            item.GetComponent<Renderer>().sharedMaterial = material;
        }
    }
}
