using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FratalUpdater : MonoBehaviour
{
    private Renderer renderer;
    void Start()
    {
        renderer = gameObject.GetComponent<Renderer>();
    }

    // Update is called once per frame
    void Update()
    {
    }
}
