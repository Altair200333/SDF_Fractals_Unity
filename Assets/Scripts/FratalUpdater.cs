using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public class FratalUpdater : MonoBehaviour
{
    private Renderer render;
    void Start()
    {
        render = gameObject.GetComponent<Renderer>();
        var path = Application.dataPath + @"/Shaders/" + "shader.hlsl";
        var shader = ShaderUtil.CreateShaderAsset(File.ReadAllText(path));
        var material = new Material(shader);

        int passCount = material.passCount;
        for (int i = 0; i < passCount; i++)
        {
            ShaderUtil.CompilePass(material, i, true);
        }

        render.material = material;
    }

    // Update is called once per frame
    void Update()
    {
    }
}
