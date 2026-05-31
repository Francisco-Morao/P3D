/**
 * common.glsl
 * Common types and functions used for ray tracing.
 */

const float pi = 3.14159265358979;
const float epsilon = 0.001;

struct Ray {
    vec3 o;     // origin
    vec3 d;     // direction - always set with normalized vector
    float t;    // time, for motion blur
};

Ray createRay(vec3 o, vec3 d, float t)
{
    Ray r;
    r.o = o;
    r.d = d;
    r.t = t;
    return r;
}

Ray createRay(vec3 o, vec3 d)
{
    return createRay(o, d, 0.0);
}

vec3 pointOnRay(Ray r, float t)
{
    return r.o + r.d * t;
}

float gSeed = 0.0;

uint baseHash(uvec2 p)
{
    p = 1103515245U * ((p >> 1U) ^ (p.yx));
    uint h32 = 1103515245U * ((p.x) ^ (p.y>>3U));
    return h32 ^ (h32 >> 16);
}

float hash1(inout float seed) {
    uint n = baseHash(floatBitsToUint(vec2(seed += 0.1,seed += 0.1)));
    return float(n) / float(0xffffffffU);
}

vec2 hash2(inout float seed) {
    uint n = baseHash(floatBitsToUint(vec2(seed += 0.1,seed += 0.1)));
    uvec2 rz = uvec2(n, n * 48271U);
    return vec2(rz.xy & uvec2(0x7fffffffU)) / float(0x7fffffff);
}

vec3 hash3(inout float seed)
{
    uint n = baseHash(floatBitsToUint(vec2(seed += 0.1, seed += 0.1)));
    uvec3 rz = uvec3(n, n * 16807U, n * 48271U);
    return vec3(rz & uvec3(0x7fffffffU)) / float(0x7fffffff);
}

float rand(vec2 v)
{
    return fract(sin(dot(v.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 toLinear(vec3 c)
{
    return pow(c, vec3(2.2));
}

vec3 toGamma(vec3 c)
{
    return pow(c, vec3(1.0 / 2.2));
}

vec2 randomInUnitDisk(inout float seed) {
    vec2 h = hash2(seed) * vec2(1.0, 6.28318530718);
    float phi = h.y;
    float r = sqrt(h.x);
	return r * vec2(sin(phi), cos(phi));
}

vec3 randomInUnitSphere(inout float seed)
{
    vec3 h = hash3(seed) * vec3(2.0, 6.28318530718, 1.0) - vec3(1.0, 0.0, 0.0);
    float phi = h.y;
    float r = pow(h.z, 1.0/3.0);
	return r * vec3(sqrt(1.0 - h.x * h.x) * vec2(sin(phi), cos(phi)), h.x);
}

vec3 randomUnitVector(inout float seed) //to be used in diffuse reflections with distribution cosine
{
    return(normalize(randomInUnitSphere(seed)));
}

struct Camera
{
    vec3 eye;
    vec3 u, v, n;
    float width, height;
    float lensRadius;
    float planeDist, focusDist;
    float time0, time1;
};

Camera createCamera(
    vec3 eye,
    vec3 at,
    vec3 worldUp,
    float fovy,
    float aspect,
    float aperture,  //diametro em multiplos do pixel size
    float focusDist,  //focal ratio
    float time0,
    float time1)
{
    Camera cam;
    if(aperture == 0.0) cam.focusDist = 1.0; //pinhole camera then focus in on vis plane
    else cam.focusDist = focusDist;
    vec3 w = eye - at;
    cam.planeDist = length(w);
    cam.height = 2.0 * cam.planeDist * tan(fovy * pi / 180.0 * 0.5);
    cam.width = aspect * cam.height;

    cam.lensRadius = aperture * 0.5 * cam.width / iResolution.x;  //aperture ratio * pixel size; (1 pixel=lente raio 0.5)
    cam.eye = eye;
    cam.n = normalize(w);
    cam.u = normalize(cross(worldUp, cam.n));
    cam.v = cross(cam.n, cam.u);
    cam.time0 = time0;
    cam.time1 = time1;
    return cam;
}

Ray getRay(Camera cam, vec2 pixel_sample)  //rnd pixel_sample viewport coordinates
{
    vec2 ls = cam.lensRadius * randomInUnitDisk(gSeed);  //ls - lens sample for DOF
    float time = cam.time0 + hash1(gSeed) * (cam.time1 - cam.time0);
    
    // Calculate eye_offset and ray direction

    vec3 eye_offset = cam.eye + ls.x * cam.u + ls.y * cam.v;

    float px = (pixel_sample.x / iResolution.x - 0.5) * cam.width;
    float py = (pixel_sample.y / iResolution.y - 0.5) * cam.height;

    vec3 pixel_pos = px * cam.u + py * cam.v - cam.n * cam.focusDist;
    vec3 ray_direction = pixel_pos - eye_offset; 

    return createRay(eye_offset, normalize(ray_direction), time);
}

// MT_ material type
#define MT_DIFFUSE 0
#define MT_METAL 1
#define MT_DIELECTRIC 2
#define MT_PLASTIC 3

struct Material
{
    int type;
    vec3 albedo;  //diffuse color
    vec3 specColor;  //the color tint for specular reflections. for metals and opaque dieletrics like coloured glossy plastic
    vec3 emissive; //
    float roughness; // controls roughness for metals. It can be used for rough refractions
    float refIdx; // index of refraction for Dielectric
    vec3 refractColor; // absorption for beer's law
};

Material createDiffuseMaterial(vec3 albedo)
{
    Material m;
    m.type = MT_DIFFUSE;
    m.albedo = albedo;
    m.specColor = vec3(0.0);
    m.roughness = 1.0;  //ser usado na iluminação direta
    m.refIdx = 1.0;
    m.refractColor = vec3(0.0);
    m.emissive = vec3(0.0);
    return m;
}

Material createMetalMaterial(vec3 specClr, float roughness)
{
    Material m;
    m.type = MT_METAL;
    m.albedo = vec3(0.0);
    m.specColor = specClr;
    m.roughness = roughness;
    m.emissive = vec3(0.0);
    return m;
}

Material createDielectricMaterial(vec3 refractClr, float refIdx, float roughness)
{
    Material m;
    m.type = MT_DIELECTRIC;
    m.albedo = vec3(0.0);
    m.specColor = vec3(0.04);
    m.refIdx = refIdx;
    m.refractColor = refractClr;  
    m.roughness = roughness;
    m.emissive = vec3(0.0);
    return m;
}

Material createPlasticMaterial(vec3 albedo, float roughness)
{
    Material m;
    m.type = MT_PLASTIC;
    m.albedo = albedo;
    m.specColor = vec3(0.04); // entre 0.04 e 0.16
    m.roughness = roughness;
    m.refIdx = 1.0; // typical IOR for plastics
    m.refractColor = vec3(0.0);
    m.emissive = vec3(0.0);
    return m;
}

struct HitRecord
{
    vec3 pos;
    vec3 normal;
    float t;            // ray parameter
    Material material;
};

float schlick(float cosine, float refIdx)
{
    float r0 = pow((1.0 - refIdx) / (1.0 + refIdx), 2.0);
    return r0 + (1.0 - r0) * pow(1.0 - cosine, 5.0);
}

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float D_GGX(float NdotH, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;
    float b = max(NdotH2 * (a2 - 1.0) + 1.0, epsilon);
    return a2 / (pi * b * b);
}

float G1_GGX_Schlick(float NdotV, float roughness)
{
    float r = 0.5 + roughness * 0.5;
    float k = (r * r) / 2.0;
    float denom = max(NdotV * (1.0 - k) + k, epsilon);
    return max(NdotV, epsilon) / denom;
}

float G_Smith(float NdotV, float NdotL, float roughness)
{
    return G1_GGX_Schlick(NdotL, roughness) * G1_GGX_Schlick(NdotV, roughness);
}

bool scatter(Ray rIn, HitRecord rec, out vec3 atten, out Ray rScattered)
{
    if(rec.material.type == MT_DIFFUSE)
    {
        vec3 scatterDir = rec.normal + randomUnitVector(gSeed);
        rScattered = createRay(rec.pos + rec.normal * epsilon, normalize(scatterDir), rIn.t);
        atten = rec.material.albedo * max(dot(rScattered.d, rec.normal), 0.0);
        return true;
    }
    if(rec.material.type == MT_METAL)
    {
        // Fuzzy specular reflection
        vec3 reflected = reflect(rIn.d, rec.normal);
        vec3 dir = reflected + rec.material.roughness * randomInUnitSphere(gSeed);
        if (dot(dir, rec.normal) <= 0.0) // prevent scattering below the surface
            dir = reflected;

        rScattered = createRay(rec.pos + rec.normal * epsilon, normalize(dir), rIn.t);
        atten = rec.material.specColor;
        return true;
    }
    if(rec.material.type == MT_DIELECTRIC)
    {
        atten = vec3(1.0);
        vec3 outwardNormal;
        float niOverNt;
        float cosine;

        if(dot(rIn.d, rec.normal) > 0.0) //hit inside
        {
            outwardNormal = -rec.normal;
            niOverNt = rec.material.refIdx;
            float dt = dot(rIn.d, rec.normal);
            cosine = sqrt(1.0 - rec.material.refIdx * rec.material.refIdx * (1.0 - dt * dt));
            atten = exp(-rec.material.refractColor * rec.t);  //Beer's law absorption
        }
        else  //hit from outside
        {
            outwardNormal = rec.normal;
            niOverNt = 1.0 / rec.material.refIdx;
            cosine = -dot(rIn.d, rec.normal); 
        }

        //Use probabilistic math to decide if scatter a reflected ray or a refracted ray

        float reflectProb;

        float dt = dot(rIn.d, outwardNormal);
        float discriminant = 1.0 - niOverNt * niOverNt * (1.0 - dt * dt);

        if (discriminant > 0.0) // total reflection only if discriminant <= 0, otherwise use Schlick's approximation for reflectance
            reflectProb = schlick(cosine, rec.material.refIdx);  
        else // total reflection
            reflectProb = 1.0;

        if( hash1(gSeed) < reflectProb)  //Reflection
        {
            vec3 reflected = reflect(rIn.d, outwardNormal);
            vec3 dir = reflected + rec.material.roughness * randomInUnitSphere(gSeed);
            if (dot(dir, rec.normal) <= 0.0) // prevent scattering below the surface
                dir = reflected;

            rScattered = createRay(rec.pos + outwardNormal * epsilon, normalize(dir), rIn.t);
        }
        else  //Refraction
        {
            vec3 refracted = refract(rIn.d, outwardNormal, niOverNt);
            vec3 dir = normalize(refracted + rec.material.roughness * randomInUnitSphere(gSeed));

            if (dot(dir, rec.normal) >= 0.0) // prevent scattering above the surface
                dir = normalize(refracted);

            rScattered = createRay(rec.pos - outwardNormal * epsilon, dir, rIn.t);
        }
        return true;
    }
    if(rec.material.type == MT_PLASTIC){
        float cosTheta = max(dot(rec.normal, -rIn.d), 0.0);
        float reflectProb = fresnelSchlick(cosTheta, rec.material.specColor).x; // use the R channel because it is monochrome for plastics

        if(hash1(gSeed) < reflectProb)  //Specular reflection
        {
            vec3 reflected = reflect(rIn.d, rec.normal);
            vec3 dir = reflected + rec.material.roughness * randomInUnitSphere(gSeed);
            if (dot(dir, rec.normal) <= 0.0) // prevent scattering below the surface
                dir = reflected;

            rScattered = createRay(rec.pos + rec.normal * epsilon, normalize(dir), rIn.t);
            atten = rec.material.specColor / (reflectProb + epsilon); // compensate the energy loss for the specular component
        }
        else  //Diffuse reflection
        {
            vec3 scatterDir = rec.normal + randomUnitVector(gSeed);
            rScattered = createRay(rec.pos + rec.normal * epsilon, normalize(scatterDir), rIn.t);
            atten = rec.material.albedo * max(dot(rScattered.d, rec.normal), 0.0) / (1.0 - reflectProb + epsilon); // compensate the energy loss for the diffuse component
        }
        return true;
    }
    return false;
}

struct Triangle {vec3 a; vec3 b; vec3 c; };

Triangle createTriangle(vec3 v0, vec3 v1, vec3 v2)
{
    Triangle t;
    t.a = v0; t.b = v1; t.c = v2;
    return t;
}

bool hit_triangle(Triangle t, Ray r, float tmin, float tmax, out HitRecord rec)
{
    vec3 v0 = t.a;
    vec3 v1 = t.b;
    vec3 v2 = t.c;

    vec3 edge1 = v1 - v0;
    vec3 edge2 = v2 - v0;

    vec3 pvec = cross(r.d, edge2);
    float det = dot(edge1, pvec);
    float invDet = 1.0 / det;

    vec3 tvec = r.o - v0;
    float u = dot(tvec, pvec) * invDet;
    if (u < 0.0 || u > 1.0) // barycentric coordinate check
        return false;

    vec3 qvec = cross(tvec, edge1);
    float v = dot(r.d, qvec) * invDet;
    if (v < 0.0 || u + v > 1.0) // barycentric coordinate check
        return false;

    float t_h = dot(edge2, qvec) * invDet;

    if (t_h <= epsilon)
        return false; // ray intersection behind the origin

    if (t_h < tmin || t_h > tmax) 
        return false;

    vec3 normal = normalize(cross(edge1, edge2));
    // Ensure normal faces against the ray direction
    if (dot(normal, r.d) > 0.0) 
        normal = -normal;

    rec.t = t_h;
    rec.normal = normal;
    rec.pos = pointOnRay(r, rec.t);

    return true;
}


struct Quad {vec3 a; vec3 b; vec3 c; vec3 d; };

Quad createQuad(vec3 v0, vec3 v1, vec3 v2, vec3 v3)
{
    Quad q;
    q.a = v0; q.b = v1; q.c = v2; q.d = v3;
    return q;
}

bool hit_quad(Quad q, Ray r, float tmin, float tmax, out HitRecord rec)
{
    if(hit_triangle(createTriangle(q.a, q.b, q.c), r, tmin, rec.t, rec)) return true;
    else if(hit_triangle(createTriangle(q.a, q.c, q.d), r, tmin, rec.t, rec)) return true;
    else return false;  
}


struct Sphere
{
    vec3 center;
    float radius;
};

Sphere createSphere(vec3 center, float radius)
{
    Sphere s;
    s.center = center;
    s.radius = radius;
    return s;
}


struct MovingSphere
{
    vec3 center0, center1;
    float radius;
    float time0, time1;
};

MovingSphere createMovingSphere(vec3 center0, vec3 center1, float radius, float time0, float time1)
{
    MovingSphere s;
    s.center0 = center0;
    s.center1 = center1;
    s.radius = radius;
    s.time0 = time0;
    s.time1 = time1;
    return s;
}

vec3 center(MovingSphere mvsphere, float time)
{
    vec3 moving_center = mvsphere.center0 + ((time - mvsphere.time0) / (mvsphere.time1 - mvsphere.time0)) * (mvsphere.center1 - mvsphere.center0);
    return moving_center;
}


/*
 * The function naming convention changes with these functions to show that they implement a sort of interface for
 * the book's notion of "hittable". E.g. hit_<type>.
 */

bool hit_sphere(Sphere s, Ray r, float tmin, float tmax, out HitRecord rec)
{
    //calculate a valid t and normal
    vec3 d = r.d;
    vec3 OC = s.center - r.o; // OC = C - O

    float b = dot(d, OC);
    float c = dot(OC, OC) - s.radius * s.radius;
    float discriminant = b * b - c;
    float t;

    if (c > 0.0) { // ray outside sphere
        
        if (b <= 0.0) // ray pointing away from sphere
            return false; // no intersection
        
        if (discriminant <= 0.0)  // ray misses the sphere
            return false; // no intersection

        t = b - sqrt(discriminant); // closer intersection
    }
    else { // ray inside sphere
        t = b + sqrt(b * b - c); // farther intersection
    }

    if (t < tmin || t > tmax)
        return false; // intersection out of bounds

    rec.t = t;
    rec.pos = pointOnRay(r, rec.t);
    rec.normal = normalize(rec.pos - s.center);
    if (s.radius < 0.0) 
        rec.normal = -rec.normal;
    
    return true;
}

bool hit_movingSphere(MovingSphere s, Ray r, float tmin, float tmax, out HitRecord rec)
{
    vec3 moving_center = center(s, r.t);
    Sphere temp_sphere = createSphere(moving_center, s.radius);
    return hit_sphere(temp_sphere, r, tmin, tmax, rec);
}

struct pointLight {
    vec3 pos;
    vec3 color;
};

pointLight createPointLight(vec3 pos, vec3 color) 
{
    pointLight l;
    l.pos = pos;
    l.color = color;
    return l;
}

struct cone{
    float cosa;	// half cone angle
    float h; // height
    vec3 c;	// tip position
    vec3 v;	// axis
};

cone createCone(float height, float radius, vec3 center, vec3 axis)
{
    cone c;
    c.h = height;
    c.cosa = cos(atan(radius, height));;
    c.c = center;
    c.v = normalize(axis);
    return c;
}

bool hit_cone(cone s, Ray r, float tmin, float tmax, out HitRecord rec)
{
    vec3 co = r.o - s.c;

    float cosa2 = s.cosa * s.cosa;  // cos²(α) needed by the quadratic

    float a = dot(r.d, s.v) * dot(r.d, s.v) - cosa2;
    float b = 2.0 * (dot(r.d, s.v) * dot(co, s.v) - dot(r.d, co) * cosa2);
    float c = dot(co, s.v) * dot(co, s.v) - dot(co, co) * cosa2;

    float det = b * b - 4.0 * a * c;
    if (det < 0.0) return false;

    det = sqrt(det);
    float t1 = (-b - det) / (2.0 * a);
    float t2 = (-b + det) / (2.0 * a);

    bool  hitFound = false;
    float t;
    vec3  cp;

    if (t1 >= tmin && t1 <= tmax)
    {
        vec3  cp1 = r.o + t1 * r.d - s.c;
        float h   = dot(cp1, s.v);
        if (h >= 0.0 && h <= s.h)
        {
            hitFound = true;
            t  = t1;
            cp = cp1;
        }
    }
    if (t2 >= tmin && t2 <= tmax && (!hitFound || t2 < t))
    {
        vec3  cp2 = r.o + t2 * r.d - s.c;
        float h   = dot(cp2, s.v);
        if (h >= 0.0 && h <= s.h)
        {
            hitFound = true;
            t  = t2;
            cp = cp2;
        }
    }

    if (!hitFound) return false;

    // correct lateral normal: project cp onto axis, subtract to get radial, 
    // then blend with axis by sina/cosa to get the actual surface normal
    float sina = sqrt(1.0 - cosa2);
    vec3 radial = normalize(cp - s.v * dot(cp, s.v));
    vec3 n = normalize(radial * s.cosa - s.v * sina);

    if (dot(n, r.d) > 0.0) 
        n = -n;

    rec.t = t;
    rec.pos = pointOnRay(r, rec.t);
    rec.normal = n;

    return true;
}


struct Cylinder {
    vec3 center;
    float height;
    float radius;
};

Cylinder createCylinder(vec3 center, float height, float radius)
{
    Cylinder c;
    c.center = center;
    c.height = height;
    c.radius = radius;
    return c;
}

bool hit_cylinder(Cylinder c, Ray r, float tmin, float tmax, out HitRecord rec) {
    vec3 upper = c.center - vec3(0.0, c.height * 0.5, 0.0);
    vec3 lower = c.center + vec3(0.0, c.height * 0.5, 0.0);

    vec3 ca = lower - upper;
    vec3 oc = r.o - upper;

    float caca = dot(ca, ca);
    float card = dot(ca, r.d);
    float caoc = dot(ca, oc);

    // Project onto plane perpendicular to axis, build quadratic equation
    float a = caca - card * card;
    float b = caca * dot(oc, r.d) - caoc * card;
    float cc = caca * dot(oc, oc) - caoc * caoc - c.radius * c.radius * caca;
    float h = b * b - a * cc;

    if (h < 0.0)
        return false;

    h = sqrt(h);
    float d = (-b - h) / a;

    // Check if side intersection is within finite length and t range
    float y = caoc + d * card;
    if (y > 0.0 && y < caca && d > tmin && d < tmax) {
        vec3 n = (oc + d * r.d - ca * y / caca) / c.radius;
        rec.t = d;
        rec.normal = normalize(n);
        rec.pos = pointOnRay(r, rec.t);
        return true;
    }

    // Test end caps
    d = ((y < 0.0 ? 0.0 : caca) - caoc) / card;
    if (d > tmin && d < tmax && abs(b + a * d) < h) {
        rec.t = d;
        rec.normal = normalize(ca * sign(y) / caca);
        rec.pos = pointOnRay(r, rec.t);
        return true;
    }

    return false;
}

mat3 rotateXYZ(vec3 angles)
{
    float cx = cos(angles.x), sx = sin(angles.x);
    float cy = cos(angles.y), sy = sin(angles.y);
    float cz = cos(angles.z), sz = sin(angles.z);

    mat3 Rx = mat3(1,0,0, 0,cx,sx, 0,-sx,cx);
    mat3 Ry = mat3(cy,0,-sy, 0,1,0, sy,0,cy);
    mat3 Rz = mat3(cz,sz,0, -sz,cz,0, 0,0,1);

    return Rz * Ry * Rx;
}

bool hit_box(vec3 center, vec3 halfSize, vec3 orientation, Ray r, float tmin, inout HitRecord rec, Material mat)
{
    bool hit = false;

    // build rotation matrix and its inverse (transpose, since it's orthonormal)
    mat3 rot = rotateXYZ(orientation);
    mat3 invRot = transpose(rot);

    // transform ray into box local space
    Ray localRay;
    localRay.o = invRot * (r.o - center);
    localRay.d = invRot * r.d;
    localRay.t = r.t;

    // now test against an axis-aligned box centered at origin
    vec3 minP = -halfSize;
    vec3 maxP =  halfSize;

    vec3 A, B, C, D;

    // FRONT (+Z)
    A = vec3(minP.x, minP.y, maxP.z);
    B = vec3(maxP.x, minP.y, maxP.z);
    C = vec3(maxP.x, maxP.y, maxP.z);
    D = vec3(minP.x, maxP.y, maxP.z);
    if(hit_quad(createQuad(A,B,C,D), localRay, tmin, rec.t, rec))
    {
        hit = true;
        rec.material = mat;
    }

    // BACK
    A = vec3(maxP.x, minP.y, minP.z);
    B = vec3(minP.x, minP.y, minP.z);
    C = vec3(minP.x, maxP.y, minP.z);
    D = vec3(maxP.x, maxP.y, minP.z);
    if(hit_quad(createQuad(A,B,C,D), localRay, tmin, rec.t, rec))
    {
        hit = true;
        rec.material = mat;
    }

    // LEFT
    A = vec3(minP.x, minP.y, minP.z);
    B = vec3(minP.x, minP.y, maxP.z);
    C = vec3(minP.x, maxP.y, maxP.z);
    D = vec3(minP.x, maxP.y, minP.z);
    if(hit_quad(createQuad(A,B,C,D), localRay, tmin, rec.t, rec))
    {
        hit = true;
        rec.material = mat;
    }

    // RIGHT
    A = vec3(maxP.x, minP.y, maxP.z);
    B = vec3(maxP.x, minP.y, minP.z);
    C = vec3(maxP.x, maxP.y, minP.z);
    D = vec3(maxP.x, maxP.y, maxP.z);
    if(hit_quad(createQuad(A,B,C,D), localRay, tmin, rec.t, rec))
    {
        hit = true;
        rec.material = mat;
    }

    // TOP
    A = vec3(minP.x, maxP.y, maxP.z);
    B = vec3(maxP.x, maxP.y, maxP.z);
    C = vec3(maxP.x, maxP.y, minP.z);
    D = vec3(minP.x, maxP.y, minP.z);
    if(hit_quad(createQuad(A,B,C,D), localRay, tmin, rec.t, rec))
    {
        hit = true;
        rec.material = mat;
    }

    // BOTTOM
    A = vec3(minP.x, minP.y, minP.z);
    B = vec3(maxP.x, minP.y, minP.z);
    C = vec3(maxP.x, minP.y, maxP.z);
    D = vec3(minP.x, minP.y, maxP.z);
    if(hit_quad(createQuad(A,B,C,D), localRay, tmin, rec.t, rec))
    {
        hit = true;
        rec.material = mat;
    }

    // rotate the normal back to world space
    if(hit)
    {
        rec.pos    = r.o + rec.t * r.d;           // world space position
        rec.normal = rot * rec.normal;             // rotate normal back to world
    }

    return hit;
}
