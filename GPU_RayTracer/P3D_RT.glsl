/**
* ver hash functions em
* https://www.shadertoy.com/view/XlGcRh hash functions GPU
* http://www.jcgt.org/published/0009/03/02/
 */

 #include "./common.glsl"
 #iChannel0 "self"

#define MAX_SAMPLES 10000.0
#define SCENE 6

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


const vec3 verts[91] = vec3[](
    vec3( 0.000000, -0.633005, -0.412728),
    vec3(-0.671199,  0.500707, -0.446292),
    vec3(-0.256375,  0.622180, -0.722116),
    vec3( 0.256376,  0.622180, -0.722115),
    vec3( 0.671200,  0.500707, -0.446292),
    vec3( 0.829649,  0.304160, -0.000000),
    vec3( 0.671200,  0.107613,  0.446292),
    vec3( 0.256376, -0.013860,  0.722116),
    vec3(-0.256375, -0.013860,  0.722116),
    vec3(-0.671199,  0.107613,  0.446292),
    vec3(-0.829648,  0.304160,  0.000000),
    vec3(-0.602355,  0.457022, -0.146536),
    vec3(-0.512393,  0.528183, -0.308119),
    vec3(-0.372275,  0.584657, -0.436352),
    vec3(-0.195717,  0.620916, -0.518682),
    vec3( 0.000000,  0.633410, -0.547052),
    vec3( 0.195717,  0.620916, -0.518682),
    vec3( 0.372276,  0.584657, -0.436352),
    vec3( 0.512395,  0.528183, -0.308119),
    vec3( 0.602355,  0.457022, -0.146536),
    vec3( 0.633354,  0.378139,  0.032581),
    vec3( 0.602355,  0.299256,  0.211697),
    vec3( 0.512394,  0.228095,  0.373280),
    vec3( 0.372276,  0.171621,  0.501513),
    vec3( 0.195717,  0.135363,  0.583844),
    vec3( 0.000000,  0.122869,  0.612213),
    vec3(-0.195716,  0.135363,  0.583844),
    vec3(-0.372275,  0.171621,  0.501513),
    vec3(-0.512393,  0.228095,  0.373280),
    vec3(-0.602354,  0.299256,  0.211697),
    vec3(-0.633353,  0.378139,  0.032581),
    vec3(-0.942957,  0.289020, -0.341449),
    vec3(-0.942664,  0.274704, -0.347650),
    vec3(-0.802127,  0.400419, -0.594399),
    vec3(-0.801878,  0.386069, -0.600522),
    vec3(-0.582779,  0.488827, -0.795142),
    vec3(-0.582598,  0.474449, -0.801202),
    vec3(-0.306385,  0.545587, -0.924027),
    vec3(-0.306290,  0.531192, -0.930047),
    vec3( 0.000000,  0.565146, -0.968437),
    vec3( 0.000000,  0.550744, -0.974443),
    vec3( 0.306386,  0.545587, -0.924027),
    vec3( 0.306291,  0.531192, -0.930047),
    vec3( 0.582780,  0.488827, -0.795142),
    vec3( 0.582599,  0.474449, -0.801202),
    vec3( 0.802133,  0.400419, -0.594399),
    vec3( 0.801878,  0.386069, -0.600522),
    vec3( 0.943484,  0.289020, -0.341449),
    vec3( 0.942665,  0.274704, -0.347650),
    vec3( 0.991484,  0.165533, -0.061051),
    vec3( 0.991176,  0.151255, -0.067339),
    vec3( 0.943484,  0.042045,  0.219346),
    vec3( 0.942665,  0.027806,  0.212971),
    vec3( 0.802133, -0.068954,  0.472297),
    vec3( 0.801878, -0.083159,  0.465843),
    vec3( 0.582780, -0.157761,  0.673039),
    vec3( 0.582599, -0.172139,  0.666523),
    vec3( 0.306386, -0.214522,  0.801924),
    vec3( 0.306291, -0.228682,  0.795368),
    vec3( 0.000000, -0.234081,  0.846334),
    vec3( 0.000000, -0.248234,  0.839765),
    vec3(-0.306385, -0.214522,  0.801924),
    vec3(-0.306290, -0.228682,  0.795368),
    vec3(-0.582779, -0.157761,  0.673039),
    vec3(-0.582598, -0.172139,  0.666523),
    vec3(-0.802127, -0.068954,  0.472297),
    vec3(-0.801865, -0.083159,  0.465843),
    vec3(-0.943457,  0.042045,  0.219346),
    vec3(-0.942664,  0.027806,  0.212971),
    vec3(-0.991333,  0.165533, -0.061051),
    vec3(-0.990825,  0.151255, -0.067339),
    vec3(-0.471332, -0.179150, -0.380189),
    vec3(-0.291299, -0.079278, -0.606965),
    vec3( 0.000000, -0.041130, -0.693586),
    vec3( 0.291300, -0.079278, -0.606965),
    vec3( 0.471332, -0.179150, -0.380189),
    vec3( 0.471332, -0.302599,  0.000000),
    vec3( 0.291301, -0.402471,  0.226778),
    vec3( 0.000000, -0.440620,  0.313399),
    vec3(-0.291299, -0.402471,  0.226778),
    vec3(-0.471332, -0.302599,  0.000000),
    vec3( 0.023567, -0.609322, -0.411101),
    vec3( 0.014565, -0.604329, -0.422440),
    vec3( 0.000000, -0.602421, -0.426771),
    vec3(-0.014565, -0.604329, -0.422440),
    vec3(-0.023566, -0.609322, -0.411101),
    vec3(-0.023566, -0.615495, -0.397085),
    vec3(-0.014565, -0.620488, -0.385746),
    vec3( 0.000000, -0.622396, -0.381415),
    vec3( 0.014565, -0.620488, -0.385746),
    vec3( 0.023567, -0.615495, -0.397085)
);

const vec3 triangles[178] = vec3[](
    vec3(1, 11, 12), vec3(2, 13, 14), vec3(3, 15, 16), vec3(4, 17, 18),
    vec3(5, 19, 20), vec3(6, 21, 22), vec3(7, 23, 24), vec3(8, 25, 26),
    vec3(9, 27, 28), vec3(10, 29, 30), vec3(14, 13, 12), vec3(14, 12, 11),
    vec3(14, 11, 30), vec3(14, 30, 29), vec3(14, 29, 28), vec3(14, 28, 27),
    vec3(14, 27, 26), vec3(14, 26, 25), vec3(14, 25, 24), vec3(14, 24, 23),
    vec3(14, 23, 22), vec3(14, 22, 21), vec3(14, 21, 20), vec3(14, 20, 19),
    vec3(14, 19, 18), vec3(14, 18, 17), vec3(14, 17, 16), vec3(13, 1, 12),
    vec3(15, 2, 14), vec3(17, 3, 16), vec3(19, 4, 18), vec3(21, 5, 20),
    vec3(23, 6, 22), vec3(25, 7, 24), vec3(27, 8, 26), vec3(29, 9, 28),
    vec3(11, 10, 30), vec3(2, 35, 1), vec3(2, 1, 13), vec3(3, 39, 2),
    vec3(3, 2, 15), vec3(4, 43, 3), vec3(4, 3, 17), vec3(5, 47, 4),
    vec3(5, 4, 19), vec3(6, 51, 5), vec3(6, 5, 21), vec3(7, 55, 6),
    vec3(7, 6, 23), vec3(8, 59, 7), vec3(8, 7, 25), vec3(9, 63, 8),
    vec3(9, 8, 27), vec3(10, 67, 9), vec3(10, 9, 29), vec3(10, 11, 1),
    vec3(10, 1, 31), vec3(1, 35, 33), vec3(2, 39, 37), vec3(3, 43, 41),
    vec3(4, 47, 45), vec3(5, 51, 49), vec3(6, 55, 53), vec3(7, 59, 57),
    vec3(8, 63, 61), vec3(9, 67, 65), vec3(10, 31, 69), vec3(47, 5, 49),
    vec3(43, 4, 45), vec3(39, 3, 41), vec3(35, 2, 37), vec3(31, 1, 33),
    vec3(67, 10, 69), vec3(63, 9, 65), vec3(59, 8, 61), vec3(55, 7, 57),
    vec3(51, 6, 53), vec3(34, 71, 32), vec3(72, 34, 36), vec3(38, 72, 36),
    vec3(73, 38, 40), vec3(42, 73, 40), vec3(74, 42, 44), vec3(46, 74, 44),
    vec3(75, 46, 48), vec3(50, 75, 48), vec3(76, 50, 52), vec3(54, 76, 52),
    vec3(77, 54, 56), vec3(58, 77, 56), vec3(78, 58, 60), vec3(62, 78, 60),
    vec3(79, 62, 64), vec3(66, 79, 64), vec3(80, 66, 68), vec3(70, 80, 68),
    vec3(81, 70, 72), vec3(71, 81, 69), vec3(32, 31, 33), vec3(32, 33, 34),
    vec3(31, 32, 70), vec3(31, 70, 69), vec3(34, 33, 35), vec3(34, 35, 36),
    vec3(36, 35, 37), vec3(36, 37, 38), vec3(38, 37, 39), vec3(38, 39, 40),
    vec3(40, 39, 41), vec3(40, 41, 42), vec3(42, 41, 43), vec3(42, 43, 44),
    vec3(44, 43, 45), vec3(44, 45, 46), vec3(46, 45, 47), vec3(46, 47, 48),
    vec3(48, 47, 49), vec3(48, 49, 50), vec3(50, 49, 51), vec3(50, 51, 52),
    vec3(52, 51, 53), vec3(52, 53, 54), vec3(54, 53, 55), vec3(54, 55, 56),
    vec3(56, 55, 57), vec3(56, 57, 58), vec3(58, 57, 59), vec3(58, 59, 60),
    vec3(60, 59, 61), vec3(60, 61, 62), vec3(62, 61, 63), vec3(62, 63, 64),
    vec3(64, 63, 65), vec3(64, 65, 66), vec3(66, 65, 67), vec3(66, 67, 68),
    vec3(68, 67, 69), vec3(68, 69, 70), vec3(74, 46, 75), vec3(74, 75, 81),
    vec3(74, 81, 82), vec3(73, 42, 74), vec3(73, 74, 82), vec3(73, 82, 83),
    vec3(72, 38, 73), vec3(72, 73, 83), vec3(72, 83, 84), vec3(71, 34, 72),
    vec3(71, 72, 84), vec3(71, 84, 85), vec3(80, 70, 71), vec3(80, 71, 85),
    vec3(80, 85, 86), vec3(79, 66, 80), vec3(79, 80, 86), vec3(79, 86, 87),
    vec3(78, 62, 79), vec3(78, 79, 87), vec3(78, 87, 88), vec3(77, 58, 78),
    vec3(77, 78, 88), vec3(77, 88, 89), vec3(76, 54, 77), vec3(76, 77, 89),
    vec3(76, 89, 90), vec3(75, 50, 76), vec3(75, 76, 90), vec3(75, 90, 81),
    vec3(82, 81, 0), vec3(83, 82, 0), vec3(84, 83, 0), vec3(85, 84, 0),
    vec3(86, 85, 0), vec3(87, 86, 0), vec3(88, 87, 0), vec3(89, 88, 0),
    vec3(90, 89, 0), vec3(81, 90, 0)
);


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

    #elif SCENE == 6

        // backgroundColor1 = vec3(0.0, 0.0, 1.0);
        // backgroundColor2 = vec3(0.0, 0.5, 0.5);

        for(int i = 0; i < 178; i++)
        {
            vec3 tri = triangles[i];
            if(hit_triangle(createTriangle(verts[int(tri.x)], verts[int(tri.y)], verts[int(tri.z)]), r, tmin, rec.t, rec))
            {
                hit = true;
                rec.material = createDielectricMaterial(vec3(0.0, 0.0, 1.0), 1.5, 0.0);
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
                rec.material.emissive = vec3(0.0f, 0.9f, 0.9f) * 20.0f;
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
                diffCol = (1.0 - F) * rec.material.albedo * pl.color * NdotL / pi;
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
