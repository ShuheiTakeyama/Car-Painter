using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class MirrorReflection : MonoBehaviour
{
	public int TextureSize = 256;
	public float ClipPlaneOffset = 0.07f;

	public LayerMask ReflectLayers = -1;

	private Hashtable ReflectionCameras = new Hashtable ();

	private RenderTexture ReflectionTexture = null;
	private int OldReflectionTextureSize = 0;

	private static bool InsideRendering = false;

	public void OnWillRenderObject ()
	{
		if (!enabled || !renderer || !renderer.sharedMaterial || !renderer.enabled)
		{
			return;
		}

		Camera currentCamera = Camera.current;
		if (!currentCamera)
		{
			return;
		}

		// Safeguard from recursive reflections
		if (InsideRendering)
		{
			return;
		}
		InsideRendering = true;

		// Create reflection camera and render texture
		Camera reflectionCamera;
		CreateMirrorObjects (currentCamera, out reflectionCamera);

		// Update camera values to match current camera
		UpdateCameraModes (currentCamera, reflectionCamera);

		// Create reflection plane
		Vector3 position = transform.position;
		Vector3 normal = transform.up;
		float d = -Vector3.Dot (normal, position) - ClipPlaneOffset;
		Vector4 reflectionPlane = new Vector4 (normal.x, normal.y, normal.z, d);

		// Create reflection matrix with reflection plane then update view matrix
		Matrix4x4 reflectionMatrix = Matrix4x4.zero;
		CalculateReflectionMatrix (ref reflectionMatrix, reflectionPlane);
		reflectionCamera.worldToCameraMatrix = currentCamera.worldToCameraMatrix * reflectionMatrix;

		// Update projection matrix
		Vector4 clipPlane = CreateCameraSpacePlane (reflectionCamera, position, normal, 1.0f);
		Matrix4x4 projectionMatrix = currentCamera.projectionMatrix;
		CalculateObliqueMatrix (ref projectionMatrix, clipPlane);
		reflectionCamera.projectionMatrix = projectionMatrix;

		// Render!
		reflectionCamera.cullingMask = ~(1 << 4) & ReflectLayers.value; // Never render water layer
		reflectionCamera.targetTexture = ReflectionTexture;
		reflectionCamera.transform.position = currentCamera.transform.position; // Update same position to current camera
		GL.SetRevertBackfacing (true);
		reflectionCamera.Render ();
		GL.SetRevertBackfacing (false);

		// Set render texture to materials
		Material[] materials = renderer.sharedMaterials;
		foreach (Material material in materials)
		{
			if (material.HasProperty ("_ReflectionTex"))
			{
				material.SetTexture ("_ReflectionTex", ReflectionTexture);
			}
		}

		// Set projection matrix that transform UVs from object space to screen space to materials 
		Matrix4x4 scaleOffsetMatrix = Matrix4x4.TRS (new Vector3 (0.5f, 0.5f, 0.5f), Quaternion.identity, new Vector3 (0.5f, 0.5f, 0.5f));
		Matrix4x4 mirrorProjectioniMatrix = scaleOffsetMatrix * currentCamera.projectionMatrix * currentCamera.worldToCameraMatrix * transform.localToWorldMatrix;
		foreach (Material material in materials)
		{
			material.SetMatrix ("_ProjMatrix", mirrorProjectioniMatrix);
		}

		InsideRendering = false;
	}

	void OnDisable ()
	{
		if (ReflectionTexture)
		{
			DestroyImmediate (ReflectionTexture);
			ReflectionTexture = null;
		}
		foreach (DictionaryEntry entry in ReflectionCameras)
		{
			DestroyImmediate (((Camera)entry.Value).gameObject);
		}
		ReflectionCameras.Clear ();
	}

	private void CreateMirrorObjects (Camera currentCamera, out Camera reflectionCamera)
	{
		reflectionCamera = null;

		// Create reflection render texture
		if (!ReflectionTexture || OldReflectionTextureSize != TextureSize)
		{
			if (ReflectionTexture)
			{
				DestroyImmediate (ReflectionTexture);
			}

			ReflectionTexture = new RenderTexture (TextureSize, TextureSize, 16);
			ReflectionTexture.name = "__MirrorReflection" + GetInstanceID ();
			ReflectionTexture.antiAliasing = 8;
			ReflectionTexture.hideFlags = HideFlags.DontSave;
			OldReflectionTextureSize = TextureSize;
		}

		// Create reflection camera
		reflectionCamera = ReflectionCameras[currentCamera] as Camera;
		if (!reflectionCamera)
		{

			GameObject newCamera = new GameObject("__MirrorReflectionCamera" + "(" + GetInstanceID () + ")" + "(" + currentCamera.GetInstanceID () + ")", typeof (Camera));
			reflectionCamera = newCamera.camera;
			reflectionCamera.enabled = false;
			reflectionCamera.transform.position = transform.position;
			reflectionCamera.transform.rotation = transform.rotation;
			newCamera.hideFlags = HideFlags.HideAndDontSave;
			ReflectionCameras[currentCamera] = reflectionCamera;
		}
	}

	private void UpdateCameraModes (Camera source, Camera destination)
	{
		destination.clearFlags = source.clearFlags;
		destination.backgroundColor = Color.white; // Mask color
		destination.farClipPlane = source.farClipPlane;
		destination.nearClipPlane = source.nearClipPlane;
		destination.orthographic = source.orthographic;
		destination.fieldOfView = source.fieldOfView;
		destination.aspect = source.aspect;
		destination.orthographicSize = source.orthographicSize;
	}

	private static void CalculateReflectionMatrix (ref Matrix4x4 reflectionMatrix, Vector4 plane)
	{
		reflectionMatrix.m00 = (-2.0f * plane[0] * plane[0] + 1.0f);
		reflectionMatrix.m01 = (-2.0f * plane[0] * plane[1]);
		reflectionMatrix.m02 = (-2.0f * plane[0] * plane[2]);
		reflectionMatrix.m03 = (-2.0f * plane[3] * plane[0]);

		reflectionMatrix.m10 = (-2.0f * plane[1] * plane[0]);
		reflectionMatrix.m11 = (-2.0f * plane[1] * plane[1] + 1.0f);
		reflectionMatrix.m12 = (-2.0f * plane[1] * plane[2]);
		reflectionMatrix.m13 = (-2.0f * plane[3] * plane[1]);

		reflectionMatrix.m20 = (-2.0f * plane[2] * plane[0]);
		reflectionMatrix.m21 = (-2.0f * plane[2] * plane[1]);
		reflectionMatrix.m22 = (-2.0f * plane[2] * plane[2] + 1.0f);
		reflectionMatrix.m23 = (-2.0f * plane[3] * plane[2]);

		reflectionMatrix.m30 = 0.0f;
		reflectionMatrix.m31 = 0.0f;
		reflectionMatrix.m32 = 0.0f;
		reflectionMatrix.m33 = 1.0f;
	}

	private Vector4 CreateCameraSpacePlane (Camera camera, Vector3 position, Vector3 normal, float sideSign)
	{
		Vector3 offsetPosition = position + normal * ClipPlaneOffset;
		Matrix4x4 world2CameraMatrix = camera.worldToCameraMatrix;
		Vector3 cameraSpacePosition = world2CameraMatrix.MultiplyPoint (offsetPosition);
		Vector3 cameraSpaceNormal = world2CameraMatrix.MultiplyVector (normal).normalized * sideSign;
		
		return new Vector4 (cameraSpaceNormal.x, cameraSpaceNormal.y, cameraSpaceNormal.z, -Vector3.Dot (cameraSpacePosition, cameraSpaceNormal));
	}

	// Extended sign
	private static float sgn (float a)
	{
		if (a > 0.0f)
		{
			return 1.0f;
		}
		else if (a < 0.0f)
		{
			return -1.0f;
		}
		else
		{
			return 0.0f;
		}
	}

	// See article in Game Programming Gems 5
	private static void CalculateObliqueMatrix (ref Matrix4x4 projection, Vector4 clipPlane)
	{
		Vector4 q = projection.inverse * new Vector4 (sgn (clipPlane.x), sgn (clipPlane.y), 1.0f, 1.0f);
		Vector4 c = clipPlane * (2.0f / (Vector4.Dot (clipPlane, q)));
		projection[2] = c.x - projection[3];
		projection[6] = c.y - projection[7];
		projection[10] = c.z - projection[11];
		projection[14] = c.w - projection[15];
	}
}
