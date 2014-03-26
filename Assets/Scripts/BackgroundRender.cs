using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class BackgroundRender : MonoBehaviour
{
	[SerializeField, Range (1, 10)]
	private int scale = 1;
	public RenderTexture renderTexture { get; private set; }
	public List<Material> materials = new List<Material> ();

	void OnPostRender ()
	{
		for (int i = 0; i < materials.Count; i++)
		{
			materials[i].SetTexture ("_RefractionMap", camera.targetTexture);
		}
	}

	void Start()
	{
		renderTexture = new RenderTexture (Screen.width / scale, Screen.height / scale, 24);
		renderTexture.enableRandomWrite = false;
		renderTexture.isPowerOfTwo = false;
		camera.targetTexture = renderTexture;
	}
}