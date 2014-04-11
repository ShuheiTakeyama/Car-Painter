using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class GenericGlass : MonoBehaviour 
{
	private static Hashtable GenericGlassCameras = new Hashtable ();
	private static bool IsRecursiveRendering = false;

	public void OnWillRenderObject ()
	{
		// Safeguard from recursive rendering
		if (IsRecursiveRendering)
		{
			return;
		}
		IsRecursiveRendering = true;

		// Create new glass camera and render texture if nothing
		Camera currentCamera = Camera.current;
		Camera genericGlassCamera = GenericGlassCameras[currentCamera] as Camera;
		if (!genericGlassCamera)
		{
			RenderTexture glassTexture = new RenderTexture (512, 512, 16);
			glassTexture.name = "__GenericGlassTexture";
			glassTexture.antiAliasing = 8;
			glassTexture.hideFlags = HideFlags.DontSave;

			GameObject newCamera = new GameObject("__GenericGlassCamera", typeof (Camera));
			genericGlassCamera = newCamera.camera;
			genericGlassCamera.enabled = false;
			genericGlassCamera.cullingMask = ~(18); // Never rendering TransparentFX layer
			genericGlassCamera.targetTexture = glassTexture;
			newCamera.hideFlags = HideFlags.HideAndDontSave;
			
			GenericGlassCameras[currentCamera] = genericGlassCamera;
		}

		// Update generic glass camera parameters to be the same as current camera parameters
		UpdateCameraParameters (genericGlassCamera, currentCamera);

		// Render!
		if (genericGlassCamera.transform.position != currentCamera.transform.position || genericGlassCamera.transform.rotation != currentCamera.transform.rotation)
		{
			genericGlassCamera.transform.position = currentCamera.transform.position;
			genericGlassCamera.transform.rotation = currentCamera.transform.rotation;
			GL.SetRevertBackfacing (false);
			genericGlassCamera.Render ();
			if (currentCamera.name.Equals ("__MirrorReflectionCamera"))
			{
				GL.SetRevertBackfacing (true);
			}
		}

		// Set render texture to materials
		Material[] materials = renderer.sharedMaterials;
		foreach (Material material in materials)
		{
			if (material.HasProperty ("_RefractionMap"))
			{
				material.SetTexture ("_RefractionMap", genericGlassCamera.targetTexture);
			}
		}
		
		IsRecursiveRendering = false;
	}

	void OnDisable ()
	{
		foreach (DictionaryEntry entry in GenericGlassCameras)
		{
			DestroyImmediate (((Camera)entry.Value).gameObject);
		}
		GenericGlassCameras.Clear ();
	}
	
	private void UpdateCameraParameters (Camera destination, Camera source)
	{
		destination.clearFlags = source.clearFlags;
		destination.backgroundColor = source.backgroundColor;
		destination.farClipPlane = source.farClipPlane;
		destination.nearClipPlane = source.nearClipPlane;
		destination.orthographic = source.orthographic;
		destination.fieldOfView = source.fieldOfView;
		destination.aspect = source.aspect;
		destination.orthographicSize = source.orthographicSize;
	}
}
