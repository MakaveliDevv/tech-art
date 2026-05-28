using UnityEngine;

public class ToonVelocityController : MonoBehaviour
{
    public Material material;

    Vector3 lastPosition;
    Vector3 velocity;

    void Start()
    {
        lastPosition = transform.position;
    }

    void Update()
    {
        velocity =
            (transform.position - lastPosition)
            / Time.deltaTime;

        material.SetVector("_Velocity", velocity);

        lastPosition = transform.position;
    }
}