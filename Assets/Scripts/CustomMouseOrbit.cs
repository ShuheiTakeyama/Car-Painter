using UnityEngine;
using System.Collections;

public class CustomMouseOrbit : MonoBehaviour 
{
	public Transform target;
	public float distance = 10.0f;
	
	public float xSpeed = 35.0f;
	public float ySpeed = 20.0f;
	
	public float yMinLimit = -20.0f;
	public float yMaxLimit = 80.0f;
	
	private float x = 0.0f;
	private float y = 0.0f;


#if UNITY_IOS && !UNITY_EDITOR
	private Vector2 previousTouchPosition = Vector2.zero;
	private float previousTouchesDistance = 0.0f;
#else
	private Vector2 previousMousePosition = Vector2.zero;
#endif

	void Start () 
	{
		var angles = transform.eulerAngles;
		x = angles.y;
		y = angles.x;
		
		// Make the rigid body not change rotation
		if (rigidbody)
		{
			rigidbody.freezeRotation = true;
		}
	}
	
	void Update ()
	{
		if (target)
		{
#if UNITY_IOS && !UNITY_EDITOR
			if (Input.touchCount == 1)
			{
				Touch touch = Input.GetTouch (0);
				if (touch.phase == TouchPhase.Began)
				{
					previousTouchPosition = touch.position;
				}
				else if (touch.phase == TouchPhase.Moved)
				{
					Vector2 delta = touch.position - previousTouchPosition;
					x += delta.x * 1.0f * Time.deltaTime;
					y -= delta.y * 1.0f * Time.deltaTime;
					previousTouchPosition = touch.position;
				}
				else
				{
					// Do nothing
				}
			} 
			else if (Input.touchCount == 2)
			{
				Touch touch0 = Input.GetTouch (0);
				Touch touch1 = Input.GetTouch (1);
				if (touch0.phase == TouchPhase.Began || touch1.phase == TouchPhase.Began)
				{
					previousTouchesDistance = Vector2.Distance (touch0.position, touch1.position);
				}
				else if (touch0.phase == TouchPhase.Moved || touch1.phase == TouchPhase.Moved)
				{
					float currentTouchesDistance = Vector2.Distance (touch0.position, touch1.position);
					distance += (previousTouchesDistance - currentTouchesDistance) * 0.1f * Time.deltaTime;
					previousTouchesDistance = currentTouchesDistance ;
				}
				else
				{
					// Do nothing
				}
			}
			else
			{
				// Do nothing
			}
#else
			if (Input.GetMouseButtonDown (0))
			{
				previousMousePosition = new Vector2 (Input.mousePosition.x, Input.mousePosition.y);
			}
			else if (Input.GetMouseButton (0))
			{
				Vector2 currentMousePosition = new Vector2 (Input.mousePosition.x, Input.mousePosition.y);
				Vector2 delta = currentMousePosition - previousMousePosition;
				x += delta.x * xSpeed * Time.deltaTime;
				y -= delta.y * ySpeed * Time.deltaTime;
				previousMousePosition = currentMousePosition;
			}
			else
			{
				// Do nothing
			}
#endif
			y = ClampAngle (y, yMinLimit, yMaxLimit);
			transform.rotation = Quaternion.Euler (y, x, 0);
			transform.position = (Quaternion.Euler (y, x, 0)) * new Vector3 (0.0f, 0.0f, -distance) + target.position;
		}
	}
	
	static float ClampAngle (float angle, float min, float max) 
	{
		if (angle < -360)
		{
			angle += 360;
		}
		if (angle > 360)
		{
			angle -= 360;
		}
		return Mathf.Clamp (angle, min, max);
	}
}
