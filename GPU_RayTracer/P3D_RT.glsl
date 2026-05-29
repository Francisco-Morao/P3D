/**
* ver hash functions em
* https://www.shadertoy.com/view/XlGcRh hash functions GPU
* http://www.jcgt.org/published/0009/03/02/
 */

 #include "./common.glsl"
 #iChannel0 "self"

#define MAX_SAMPLES 10000.0
#define SCENE 5

bool russianRoulette = true;
bool NEE = true;

const float c_minCameraAngle = 0.01f;
const float c_maxCameraAngle = (pi - 0.01f);
vec3 c_cameraAt = vec3(0.0f, 0.0f, 0.0f);
float c_cameraDistance = 40.0f;
const float c_zoomMin = 2.0;
const float c_zoomMax = 80.0;
const float c_zoomSpeed = 0.2;  // distance units per pixel dragged
vec3 backgroundColor1 = vec3(0.0f);
vec3 backgroundColor2 = vec3(0.0f);

bool hit_world(Ray r, float tmin, float tmax, inout HitRecord rec)
{
    bool hit = false;
    rec.t = tmax;
    backgroundColor1 = vec3(1.0);
    backgroundColor2 = vec3(0.5, 0.7, 1.0);

    // Scene 0 = Shirley Weekend scene
    // Scene 1 = transparent orange spheres of increasing surface roughness
    // Scene 2 = opaque plastic spheres with increasing roughness
    // Scene 3 = hollow sphere with orbiting metallic spheres 
    // Scene 4 = DOF scene
    // Scene 5 = complex Cornell box scene

    #if SCENE == 0       //Shirley Weekend scene

        if(hit_quad(createQuad(vec3(-10.0, -0.05, 10.0), vec3(10.0, -0.05, 10.0), vec3(10.0, -0.05, -10.0), vec3(-10.0, -0.05, -10.0)), r, tmin, rec.t, rec))
        {
            hit = true;
            rec.material = createDiffuseMaterial(vec3(0.2));
        }

        if(hit_sphere(createSphere(vec3(-4.0, 1.0, 0.0), 1.0), r, tmin, rec.t, rec))
        {
            hit = true;
            rec.material = createDiffuseMaterial(vec3(0.2, 0.95, 0.1));
            //rec.material = createDiffuseMaterial(vec3(0.4, 0.2, 0.1));
        }

        if(hit_sphere(createSphere(vec3(4.0, 1.0, 0.0), 1.0),r,tmin,rec.t,rec))
        {
            hit = true;
            rec.material = createMetalMaterial(vec3(0.7, 0.6, 0.5), 0.0);
        }

        if(hit_sphere(createSphere(vec3(-1.5, 1.0, 0.0), 1.0),r,tmin,rec.t,rec))
        {
            hit = true;
            rec.material = createDielectricMaterial(vec3(0.0), 1.33, 0.0);
        }

        if(hit_sphere(createSphere(vec3(-1.5, 1.0, 0.0), -0.5),r,tmin,rec.t,rec))
        {
            hit = true;
            rec.material = createDielectricMaterial(vec3(0.0), 1.33, 0.0);
        }

        if(hit_sphere(createSphere(vec3(1.5, 1.0, 0.0), 1.0),r,tmin,rec.t,rec))
        {
            hit = true;
            rec.material = createDielectricMaterial(vec3(0.0, 0.9, 0.9), 1.5, 0.0);
        }
            
        int numxy = 5;
        
        for(int x = -numxy; x < numxy; ++x)
        {
            for(int y = -numxy; y < numxy; ++y)
            {
                float fx = float(x);
                float fy = float(y);
                float seed = fx + fy / 1000.0;
                vec3 rand1 = hash3(seed);
                vec3 center = vec3(fx + 0.9 * rand1.x, 0.2, fy + 0.9 * rand1.y);
                float chooseMaterial = rand1.z;
                if(distance(center, vec3(4.0, 0.2, 0.0)) > 0.9)
                {
                    if(chooseMaterial < 0.3)
                    {
                        vec3 center1 = center + vec3(0.0, hash1(gSeed) * 0.5, 0.0);
                        // diffuse
                        if(hit_movingSphere(createMovingSphere(center, center1, 0.2, 0.0, 1.0),r,tmin,rec.t,rec))
                        {
                            hit = true;
                            rec.material = createDiffuseMaterial(hash3(seed) * hash3(seed));
                        }
                    }
                    else if(chooseMaterial < 0.5)
                    {
                        // diffuse
                        if(hit_sphere(createSphere(center, 0.2),r,tmin,rec.t,rec))
                        {
                            hit = true;
                            rec.material = createDiffuseMaterial(hash3(seed) * hash3(seed));
                        }
                    }
                    else if(chooseMaterial < 0.7)
                    {
                        // metal
                        if(hit_sphere(createSphere(center, 0.2),r,tmin,rec.t,rec))
                        {
                            hit = true;
                            rec.material = createMetalMaterial((hash3(seed) + 1.0) * 0.5, 0.0);
                        }
                    }
                    else if(chooseMaterial < 0.9)
                    {
                        // metal
                        if(hit_sphere(createSphere(center, 0.2),r,tmin,rec.t,rec))
                        {
                            hit = true;
                            rec.material = createMetalMaterial((hash3(seed) + 1.0) * 0.5, hash1(seed));
                        }
                    }
                    else
                    {
                        // glass (Dielectric)
                        if(hit_sphere(createSphere(center, 0.2),r,tmin,rec.t,rec))
                        {
                            hit = true;
                            rec.material = createDielectricMaterial(hash3(seed), 1.33, 0.0);
                        }
                    }
                }
            }
        }
    #elif SCENE == 1 //from https://blog.demofox.org/2020/06/14/casual-shadertoy-path-tracing-3-fresnel-rough-refraction-absorption-orbit-camera/

        // diffuse floor
        
            vec3 A = vec3(-25.0f, -12.5f, 10.0f);
            vec3 B = vec3( 25.0f, -12.5f, 10.0f);
            vec3 C = vec3( 25.0f, -12.5f, -5.0f);
            vec3 D = vec3(-25.0f, -12.5f, -5.0f);

            if(hit_quad(createQuad(A, B, C, D), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(0.7));
            }

        //stripped background
        {
            vec3 A = vec3(-25.0f, -10.5f, -5.0f);
            vec3 B = vec3( 25.0f, -10.5f, -5.0f);
            vec3 C = vec3( 25.0f, -1.5f, -5.0f);
            vec3 D = vec3(-25.0f, -1.5f, -5.0f);
        
            if(hit_quad(createQuad(A, B, C, D), r, tmin, rec.t, rec))
            {
                hit = true;
                float shade = floor(mod(rec.pos.x, 1.0f) * 2.0f);
                rec.material = createDiffuseMaterial(vec3(shade));
            }
        }

        // ceiling piece above light
        
        {
            vec3 A = vec3(-7.5f, 12.5f, 5.0f);
            vec3 B = vec3( 7.5f, 12.5f, 5.0f);
            vec3 C = vec3( 7.5f, 12.5f, -5.0f);
            vec3 D = vec3(-7.5f, 12.5f, -5.0f);

            if(hit_quad(createQuad(A, B, C, D), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(0.7));
            }
        }    
       
        // light
        
        {
            vec3 A = vec3(-5.0f, 12.3f,  2.5f);
            vec3 B = vec3( 5.0f, 12.3f,  2.5f);
            vec3 C = vec3( 5.0f, 12.3f,  -2.5f);
            vec3 D = vec3(-5.0f, 12.3f,  -2.5f);

             if(hit_quad(createQuad(A, B, C, D), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(0.0));
                rec.material.emissive = vec3(1.0f, 0.9f, 0.9f) * 20.0f;
            }
        }
 
        const int c_numSpheres = 7;
        for (int sphereIndex = 0; sphereIndex < c_numSpheres; ++sphereIndex)
        {
            vec3 center = vec3(-18.0 + 6.0 * float(sphereIndex), -8.0, 0.0);
            if(hit_sphere(createSphere(center, 2.8),r,tmin,rec.t,rec))
            {
                hit = true;
                float r = float(sphereIndex) / float(c_numSpheres-1) * 0.1f;
                rec.material = createDielectricMaterial(vec3(0.0, 0.5, 1.0), 1.1, r);
            }
        }

    #elif SCENE == 2
        if(hit_quad(createQuad(vec3(-20.0, -12.0, 20.0), vec3(20.0, -12.0, 20.0), vec3(20.0, -12.0, -10.0), vec3(-20.0, -12.0, -10.0)), r, tmin, rec.t, rec))
        {
            hit = true;
            rec.material = createDiffuseMaterial(vec3(0.2));
        }

        const int c_numSpheres = 5;
        float roughness = 0.0;
        for (int sphereIndex = 0; sphereIndex < c_numSpheres; ++sphereIndex)
        {
            vec3 center = vec3(-12.0 + 6.0 * float(sphereIndex), -8.0, 0.0);
            if(hit_sphere(createSphere(center, 2.8),r,tmin,rec.t,rec))
            {
                hit = true;
                rec.material = createMetalMaterial(vec3(0.7, 0.6, 0.5), roughness);
            }
            roughness += 0.25;
        }
        // light
        
        {
            vec3 A = vec3(-5.0f, 12.3f,  2.5f);
            vec3 B = vec3( 5.0f, 12.3f,  2.5f);
            vec3 C = vec3( 5.0f, 12.3f,  -2.5f);
            vec3 D = vec3(-5.0f, 12.3f,  -2.5f);

             if(hit_quad(createQuad(A, B, C, D), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(0.0));
                rec.material.emissive = vec3(1.0f, 0.9f, 0.9f) * 20.0f;
            }
        }
        roughness = 0.0;
        for (int sphereIndex = 0; sphereIndex < c_numSpheres; ++sphereIndex)
        {
            vec3 center = vec3(-12.0 + 6.0 * float(sphereIndex), -8.0, 10.0);
            if(hit_sphere(createSphere(center, 2.8),r,tmin,rec.t,rec))
            {
                hit = true;
                float r = float(sphereIndex) / float(c_numSpheres-1) * 0.1f;
                rec.material = createPlasticMaterial(vec3(0.9, 0.3, 0.1), roughness);
            }
            roughness += 0.25;
        }


    #elif SCENE == 3

        backgroundColor1 = vec3(1.0);
        backgroundColor2 = vec3(0.2, 0.6, 1.0);

        if(hit_sphere(createSphere(vec3(0.0), 1.0),r,tmin,rec.t,rec))
        {
            hit = true;
            rec.material = createDielectricMaterial(vec3(0.0), 1.33, 0.0);
        }

        if(hit_sphere(createSphere(vec3(0.0), -0.5),r,tmin,rec.t,rec))
        {
            hit = true;
            rec.material = createDielectricMaterial(vec3(0.0), 1.33, 0.0);
        }

        // Moving metallic spheres
        for(int i = 0; i < 30; i++)
        {
            // Initial orbit position
            float angle0 = float(i) + iTime * 0.1;
            // spheres in a circular path in the XZ plane while oscillating up and down in the Y axis
            // circles in a circle of radius 3.0 
            vec3 startPos = vec3(cos(angle0) * 3.0, sin(angle0 * 2.0), sin(angle0) * 3.0);

            // Target orbit position
            float angle1 = angle0 + 0.3;
            vec3 endPos = vec3(cos(angle1) * 3.0, sin(angle1 * 2.0), sin(angle1) * 3.0);

            MovingSphere ms = createMovingSphere(startPos, endPos, 0.2, 0.0, 1.1);

            if(hit_movingSphere(ms, r, tmin, rec.t, rec))
            {
                hit = true;
                vec3 color = 0.5 + 0.5 * cos(float(i) + vec3(1.0, 2.0, 4.0));
                rec.material = createMetalMaterial(color, 0.0);
            }
        }

    #elif SCENE == 4
        if(hit_quad(createQuad(vec3(-10.0, -0.05, 15.0), vec3(10.0, -0.05, 15.0), vec3(10.0, -0.05, -5.0), vec3(-10.0, -0.05, -5.0)), r, tmin, rec.t, rec))
        {
            hit = true;
            rec.material = createDiffuseMaterial(vec3(0.7));
        }

        // near sphere (blurred) - closer than focus plane
        if(hit_sphere(createSphere(vec3(0.0, 1.0, -4.0), 1.0), r, tmin, rec.t, rec))
        {
            hit = true;
            rec.material = createDiffuseMaterial(vec3(0.9, 0.2, 0.2)); // red
        }

        // middle sphere (sharp) - at focus plane
        if(hit_sphere(createSphere(vec3(0.0, 1.0, 0.0), 1.0), r, tmin, rec.t, rec))
        {
            hit = true;
            rec.material = createDiffuseMaterial(vec3(0.2, 0.9, 0.2)); // green - in focus
        }

        // far sphere (blurred) - further than focus plane
        if(hit_sphere(createSphere(vec3(0.0, 1.0, 5.0), 1.0), r, tmin, rec.t, rec))
        {
            hit = true;
            rec.material = createDiffuseMaterial(vec3(0.2, 0.2, 0.9)); // blue
        }
        
    #elif SCENE == 5
        float s = 15.0;
        backgroundColor1 = vec3(0.0);
        backgroundColor2 = vec3(0.0);

        // floor
        {
            vec3 A = vec3(-s, -s, -s);
            vec3 B = vec3( s, -s, -s);
            vec3 C = vec3( s, -s,  s);
            vec3 D = vec3(-s, -s,  s);
            if(hit_quad(createQuad(A, B, C, D), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(1.0));
            }
        }
        
        // ceiling
        {
            vec3 A = vec3(-s, s, -s);
            vec3 B = vec3(-s, s,  s);
            vec3 C = vec3( s, s,  s);
            vec3 D = vec3( s, s, -s);
        
            if(hit_quad(createQuad(A, B, C, D), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(1.0));
            }
        }

        // back wall
        {
            vec3 A = vec3(-s, -s, -s);
            vec3 B = vec3(-s, -s,  s);
            vec3 C = vec3(-s,  s,  s);
            vec3 D = vec3(-s,  s, -s);
            if(hit_quad(createQuad(A, B, C, D), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(1.0));
            }
        } 

        // left wall
        {
            vec3 A = vec3(-s, -s, -s);
            vec3 B = vec3(-s,  s, -s);
            vec3 C = vec3( s,  s, -s);
            vec3 D = vec3( s, -s, -s);
            if(hit_quad(createQuad(A, B, C, D), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(1.0, 0.0, 0.0));
            }
        } 
       
        // right wall
        {
            vec3 A = vec3(-s, -s,  s);
            vec3 B = vec3(-s,  s,  s);
            vec3 C = vec3( s,  s,  s);
            vec3 D = vec3( s, -s,  s);
            if(hit_quad(createQuad(A, B, C, D), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(0.0, 1.0, 0.0));
            }
        } 

        // light
        {
            vec3 A = vec3(-10.0, 14.8, 0.0);
            vec3 B = vec3(0.0, 14.8, 0.0);
            vec3 C = vec3(0.0, 14.8, 10.0);
            vec3 D = vec3(-10.0, 14.8, 10.0);

             if(hit_quad(createQuad(A, B, C, D), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(0.0));
                rec.material.emissive = vec3(1.0f, 0.9f, 0.7f) * 15.0f;
            }
        }

        // big cylinder
        {
            if(hit_cylinder(createCylinder(vec3(5.0, 0.0, -7.0), 24.0, 3.0), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(1.0));
            }
        }

        {
            if(hit_cylinder(createCylinder(vec3(-8, -12, 9.0), 6.0, 3.0), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(1.0));
            }

        }

        {
            if(hit_cone(createCone(2.5, 3.0, vec3(-8, -6.5, 9.0), vec3(0.0, -1.0, 0.0)), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(1.0));
            }

        }

        {
            if(hit_cone(createCone(3.0, 3.0, vec3(5.0, 12.0, -7.0), vec3(0.0, 1.0, 0.0)), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(1.0));
            }
        }

        {
            if(hit_cone(createCone(3.0, 3.0, vec3(5.0, -12.0, -7.0), vec3(0.0, -1.0, 0.0)), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(1.0));
            }
        }

        {
            if(hit_cone(createCone(2.0, 2.0, vec3(0.0, -5.0, 0.0), vec3(0.0, 0.0, 1.0)), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(1.0));
            }
        }

        {
            if(hit_cone(createCone(2.0, 2.0, vec3(0.0, -5.0, 0.0), vec3(0.0, 0.0, -1.0)), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDiffuseMaterial(vec3(1.0));
            }
        }

        {
            if(hit_box(vec3(-8.5, -3.0, 9.0), vec3(2.0, 2.0, 2.0), vec3(radians(45.0), 0.0, radians(45.0)), r, tmin, 
                rec, createMetalMaterial(vec3(0.0, 0.5, 1.0), 0.3)))
            {
                hit = true;
            }
        }
    #endif

    return hit;
}

vec3 directlighting(pointLight pl, Ray r, HitRecord rec){
    vec3 diffCol, specCol;
    vec3 colorOut = vec3(0.0, 0.0, 0.0);
    float shininess = (8.0 / pow(rec.material.roughness, 4.0) + epsilon) - 2.0;

    HitRecord dummy;

    Ray shadowRay;
    vec3 V = normalize(-r.d);
    
    // Random 2D offset in the disk
    vec2 rnd = randomInUnitDisk(gSeed) - vec2(0.5, 0.5); // Center around (0, 0)
    vec3 lightPos = pl.pos + pl.pos * vec3(rnd.x, rnd.y, 0.0) * rec.material.emissive;

    vec3 lightDir = lightPos - rec.pos;
    float lightDistance = length(lightDir);
    lightDir = normalize(lightDir);

    if (dot(rec.normal, lightDir) > 0.0)
    {
        shadowRay = createRay(rec.pos + rec.normal * epsilon, lightDir, r.t);
        
        if (!hit_world(shadowRay, epsilon, lightDistance, dummy)){
            float NdotL = max(dot(rec.normal, lightDir), 0.0);
            vec3 H = normalize(lightDir + V);
            float NdotH = max(dot(rec.normal, H), 0.0);
            float NdotV = max(dot(rec.normal, V), 0.0);

            if (rec.material.type == MT_METAL || rec.material.type == MT_PLASTIC){ // Cook-Torrance
                vec3 F = fresnelSchlick(max(dot(H, V), 0.0), vec3(0.04));
                float D = D_GGX(NdotH, rec.material.roughness);
                float G = G_Smith(NdotV, NdotL, rec.material.roughness);
                diffCol = vec3(0.0); // no diffuse term for metal/plastic
                specCol = NdotL * pl.color * F * G * D / (4.0 * NdotV * NdotL + epsilon);
            }
            else{ // bling-Fong
                diffCol = pl.color * rec.material.albedo * NdotL;
                specCol = pl.color * rec.material.specColor * pow(NdotH, shininess);
            }

            colorOut = diffCol + specCol;
        }
    }
	return colorOut; 
}

#define MAX_BOUNCES 10
vec3 rayColor(Ray r)
{
    HitRecord rec;
    vec3 col = vec3(0.0);
    vec3 throughput = vec3(1.0f, 1.0f, 1.0f);
    for(int i = 0; i < MAX_BOUNCES; ++i)
    {
        if(hit_world(r, 0.001, 10000.0, rec))
        {
            col += throughput * rec.material.emissive;
            
            //calculate direct lighting with 3 white point lights:
            if (NEE) {
                // col += directlighting(createPointLight(vec3(-10.0, 15.0, 0.0), vec3(1.0, 1.0, 1.0)), r, rec) * throughput;
                // col += directlighting(createPointLight(vec3(8.0, 15.0, 3.0), vec3(1.0, 1.0, 1.0)), r, rec) * throughput;
                // col += directlighting(createPointLight(vec3(1.0, 15.0, -9.0), vec3(1.0, 1.0, 1.0)), r, rec) * throughput;                    
            }
           
            // 3. Calculate secondary ray and update throughput for the next bounce
            Ray scatterRay;
            vec3 atten;
            if(scatter(r, rec, atten, scatterRay))
            {
                r = scatterRay;
                throughput *= atten;

                if (russianRoulette)
                {
                    float rayProbability = max(throughput.r, max(throughput.g, throughput.b));
                    if (hash1(gSeed) > rayProbability) 
                        break;  
                    throughput /= rayProbability;
                }
            }
            else
            {
                break;
            }
        
        }
        else  //background
        {
            float t = 0.8 * (r.d.y + 1.0);
            col += throughput * mix(backgroundColor1, backgroundColor2, t);
            break;
        }
    }
    return col;
}

void GetCameraVectors(out vec3 cameraPos, out vec3 cameraFwd, out vec3 cameraUp, out vec3 cameraRight)
{
    vec4 orbitPx = texture(iChannel0, vec2(3.5, 0.5) / iResolution.xy);
    vec2 mouse = orbitPx.w > 0.5 ? orbitPx.xy : iMouse.xy;
    if (dot(mouse, vec2(1.0f, 1.0f)) == 0.0f)
    {
        cameraPos = vec3(0.0f, 0.0f, -c_cameraDistance);
        cameraFwd = vec3(0.0f, 0.0f, 1.0f);
        cameraUp = vec3(0.0f, 1.0f, 0.0f);
        cameraRight = vec3(1.0f, 0.0f, 0.0f);
        return;
    }
     
    // otherwise use the mouse position to calculate camera position and orientation
     
    float angleX = -mouse.x * 16.0f / float(iResolution.x);
    float angleY = mix(c_minCameraAngle, c_maxCameraAngle, mouse.y / float(iResolution.y));
     
    cameraPos.x = sin(angleX) * sin(angleY) * c_cameraDistance;
    cameraPos.y = -cos(angleY) * c_cameraDistance;
    cameraPos.z = cos(angleX) * sin(angleY) * c_cameraDistance;
     
    cameraPos += c_cameraAt;
     
    cameraFwd = normalize(c_cameraAt - cameraPos);
    cameraRight = normalize(cross(vec3(0.0f, 1.0f, 0.0f), cameraFwd));
    cameraUp = normalize(cross(cameraFwd, cameraRight));   
}

float readZoom() {
    vec4 px = texture(iChannel0, vec2(1.5, 0.5) / iResolution.xy);
    return (px.w > 0.5) ? clamp(px.x, c_zoomMin, c_zoomMax) : 10.0;
}

void CameraConfig(inout float aperture, inout float distToFocus) {
    if (SCENE == 4)
    {
        aperture = 15.0f;
        distToFocus = 10.0f;
    }
    else
    {
        aperture = 0.0f;
        distToFocus = 1.0f;
    }
}

void main()
{
    gSeed = float(baseHash(floatBitsToUint(gl_FragCoord.xy))) / float(0xffffffffU) + iTime;

    bool isZoomPixel = (gl_FragCoord.x >= 1.0 && gl_FragCoord.x < 2.0 && gl_FragCoord.y < 1.0);
    bool isPrevMousePixel = (gl_FragCoord.x >= 2.0 && gl_FragCoord.x < 3.0 && gl_FragCoord.y < 1.0);
    bool isOrbitPixel = (gl_FragCoord.x >= 3.0 && gl_FragCoord.x < 4.0 && gl_FragCoord.y < 1.0);

    float prevZoom = readZoom();
    float prevMouseY = texture(iChannel0, vec2(2.5, 0.5) / iResolution.xy).x;

    vec4 orbitPx = texture(iChannel0, vec2(3.5, 0.5) / iResolution.xy);
    vec2 orbitMouse = orbitPx.w > 0.5 ? orbitPx.xy : iMouse.xy;
    if (iMouseButton.x != 0.0)
        orbitMouse = iMouse.xy;

    // zoom 
    float newZoom = prevZoom;
    bool  zoomChanged = false;
    if (iMouseButton.y != 0.0) {
        float delta = iMouse.y - prevMouseY;
        newZoom = clamp(prevZoom + (-delta * c_zoomSpeed), c_zoomMin, c_zoomMax);
        zoomChanged = abs(newZoom - prevZoom) > 0.001;
    }

    if (isZoomPixel) {
        gl_FragColor = vec4(newZoom, 0.0, 0.0, 1.0);
        return;
    }
    if (isPrevMousePixel) {
        gl_FragColor = vec4(iMouse.y, 0.0, 0.0, 1.0);
        return;
    }
    if (isOrbitPixel) {
        gl_FragColor = vec4(orbitMouse, 0.0, 1.0);
        return;
    }

    // camera
    c_cameraDistance = newZoom;
    vec3 camPos, cameraFwd, cameraUp, cameraRight;
    GetCameraVectors(camPos, cameraFwd, cameraUp, cameraRight);

    float fovy = 60.0;
    float aperture = 0.0;
    float distToFocus = 1.0;
    float time0 = 0.0;
    float time1 = 1.0;
    CameraConfig(aperture, distToFocus);
    Camera cam = createCamera(
        camPos,
        cameraFwd,
        cameraUp,    // world up vector
        fovy,
        iResolution.x / iResolution.y,
        aperture,
        distToFocus,
        time0,
        time1);

//usa-se o 4 canal de cor para guardar o numero de samples e não o iFrame pois quando se mexe o rato faz-se reset

    vec4 prev = texture(iChannel0, gl_FragCoord.xy / iResolution.xy);
    vec3 prevLinear = toLinear(prev.xyz);  

    vec2 ps = gl_FragCoord.xy + hash2(gSeed);
    //vec2 ps = gl_FragCoord.xy;
    vec3 color = rayColor(getRay(cam, ps));

    if (iMouseButton.x != 0.0 || iMouseButton.y != 0.0 || zoomChanged) {
        gl_FragColor = vec4(toGamma(color), 1.0);  //samples number reset = 1
        return;
    }
    if(prev.w > MAX_SAMPLES)   
    {
        gl_FragColor = prev;
        return;
    }

    float w = prev.w + 1.0;
    color = mix(prevLinear, color, 1.0/w);
    gl_FragColor = vec4(toGamma(color), w);
}
