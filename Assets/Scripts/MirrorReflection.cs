using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class MirrorReflection : MonoBehaviour
{
	public float ClipPlaneOffset = 0.07f;

	private static Hashtable MirrorReflectionCameras = new Hashtable ();
	private static bool IsRecursiveRendering = false;
	
	public void OnWillRenderObject ()
	{
		// Safeguard from recursive rendering
		if (IsRecursiveRendering)
		{
			return;
		}
		IsRecursiveRendering = true;

		// Create new mirror reflection camera and render texture if nothing
		Camera currentCamera = Camera.current;
		Camera mirrorReflectionCamera = MirrorReflectionCameras[currentCamera] as Camera;
		if (!mirrorReflectionCamera)
		{
			RenderTexture mirrorReflectionTexture = new RenderTexture (512, 512, 16);
			mirrorReflectionTexture.name = "__MirrorReflectionTexture";
			mirrorReflectionTexture.antiAliasing = 8;
			mirrorReflectionTexture.hideFlags = HideFlags.DontSave;
			
			GameObject newCamera = new GameObject("__MirrorReflectionCamera", typeof (Camera));
			mirrorReflectionCamera = newCamera.camera;
			mirrorReflectionCamera.enabled = false;
			mirrorReflectionCamera.cullingMask = ~(16); // Never rendering TransparentFX and Waterlayer
			mirrorReflectionCamera.targetTexture = mirrorReflectionTexture;
			newCamera.hideFlags = HideFlags.HideAndDontSave;
			
			MirrorReflectionCameras[currentCamera] = mirrorReflectionCamera;
		}

		// Update mirror reflection camera parameters to be the same as current camera parameters
		UpdateCameraParameters (mirrorReflectionCamera, currentCamera);

		// Create reflection plane
		Vector3 position = transform.position;
		Vector3 normal = transform.up;
		float d = -Vector3.Dot (normal, position) - ClipPlaneOffset;
		Vector4 reflectionPlane = new Vector4 (normal.x, normal.y, normal.z, d);

		// Create reflection matrix with reflection plane then update view matrix
		Matrix4x4 reflectionMatrix = Matrix4x4.zero;
		CalculateReflectionMatrix (ref reflectionMatrix, reflectionPlane);
		mirrorReflectionCamera.worldToCameraMatrix = currentCamera.worldToCameraMatrix * reflectionMatrix;

		// Update projection matrix
		Vector4 clipPlane = CreateCameraSpacePlane (mirrorReflectionCamera, position, normal, 1.0f);
		Matrix4x4 projectionMatrix = currentCamera.projectionMatrix;
		CalculateObliqueMatrix (ref projectionMatrix, clipPlane);
		mirrorReflectionCamera.projectionMatrix = projectionMatrix;

		// Render!
		if (mirrorReflectionCamera.transform.position != currentCamera.transform.position || mirrorReflectionCamera.transform.rotation != currentCamera.transform.rotation)
		{
			mirrorReflectionCamera.transform.position = currentCamera.transform.position;
			mirrorReflectionCamera.transform.rotation = currentCamera.transform.rotation;
			GL.SetRevertBackfacing (true);
			mirrorReflectionCamera.Render ();
			GL.SetRevertBackfacing (false);
		}

		// Set render texture to materials
		Material[] materials = renderer.sharedMaterials;
		foreach (Material material in materials)
		{
			if (material.HasProperty ("_MirrorReflectionMap"))
			{
				material.SetTexture ("_MirrorReflectionMap", mirrorReflectionCamera.targetTexture);
			}
		}

		// Set projection matrix that transform UVs from object space to screen space to materials 
		Matrix4x4 scaleOffsetMatrix = Matrix4x4.TRS (new Vector3 (0.5f, 0.5f, 0.5f), Quaternion.identity, new Vector3 (0.5f, 0.5f, 0.5f));
		Matrix4x4 mirrorProjectionMatrix = scaleOffsetMatrix * currentCamera.projectionMatrix * currentCamera.worldToCameraMatrix * transform.localToWorldMatrix;
		foreach (Material material in materials)
		{
			material.SetMatrix ("_MirrorProjectionMatrix", mirrorProjectionMatrix);
		}

		IsRecursiveRendering = false;
	}
	
	void OnDisable ()
	{
		foreach (DictionaryEntry entry in MirrorReflectionCameras)
		{
			DestroyImmediate (((Camera)entry.Value).gameObject);
		}
		MirrorReflectionCameras.Clear ();
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
