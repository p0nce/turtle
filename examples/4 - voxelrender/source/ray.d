module ray;

import core.stdc.float_;
import inteli;
import std.math;
import dplug.math;
import dplug.core;

import voxd;

// FUTURE: use only Godot-math, needs AABB and .ptr for godot-math types

struct Ray
{
nothrow:
    enum int N = 3;
    alias T = float;

    public
    {
        alias point_t = vec3f;
        point_t orig;
        point_t dir;

        /// Returns: A point further along the ray direction.
        @nogc point_t progress(T t) pure const nothrow
        {
            return orig + dir * t;
        }

        /// Ray vs triangle intersection.
        /// See_also: "Fast, Minimum Storage Ray/Triangle intersection", Mommer & Trumbore (1997)
        /// Returns: Barycentric coordinates, the intersection point is at $(D (1 - u - v) * A + u * B + v * C).
        @nogc bool intersectTriangle(vec3f A, vec3f B, vec3f C, out T t, out T u, out T v) pure const nothrow
        {
            point_t edge1 = B - A;
            point_t edge2 = C - A;
            point_t pvec = cross(dir, edge2);
            T det = dot(edge1, pvec);
            if (fast_fabs(det) < T.epsilon)
                return false; // no intersection
            T invDet = 1 / det;

            // calculate distance from triangle.a to ray origin
            point_t tvec = orig - A;

            // calculate U parameter and test bounds
            u = dot(tvec, pvec) * invDet;
            if (u < 0 || u > 1)
                return false;

            // prepare to test V parameter
            point_t qvec = cross(tvec, edge1);

            // calculate V parameter and test bounds
            v = dot(dir, qvec) * invDet;
            if (v < 0.0 || u + v > 1.0)
                return false;

            // calculate t, ray intersects triangle
            t = dot(edge2, qvec) * invDet;
            return true;
        }
/*
        /// Ray vs quad intersection.
        /// See_also: "Fast, Minimum Storage Ray/Triangle intersection", Mommer & Trumbore (1997)
        /// Returns: Barycentric coordinates, the intersection point is at $(D (1 - u - v) * A + u * B + v * C).
        /// The quad is (A, B, C + B - A, C).
        ///
        ///  A --------- B
        ///  |           |
        ///  |           |
        ///  C---------(C+B-A)
        ///
        /// Taking 4D vectors instead
        @nogc bool intersectQuad(vec3f A, vec3f B, vec3f C, out T t, out T u, out T v) pure const nothrow
        {
            point_t edge1 = B - A;
            point_t edge2 = C - A;
            point_t pvec = cross(dir, edge2);
            T det = dot(edge1, pvec);
            if (fast_fabs(det) < T.epsilon)
                return false; // no intersection
            T invDet = 1 / det;

            // calculate distance from triangle.a to ray origin
            point_t tvec = orig - A;

            // calculate U parameter and test bounds
            u = dot(tvec, pvec) * invDet;
            if (u < 0 || u > 1)
                return false;

            // prepare to test V parameter
            point_t qvec = cross(tvec, edge1);

            // calculate V parameter and test bounds
            v = dot(dir, qvec) * invDet;
            if (v < 0.0 || u > 1.0 || v > 1.0)
                return false;

            // calculate t, ray intersects triangle
            t = dot(edge2, qvec) * invDet;
            return true;
        }*/
    }
}

 bool intersectVOX(Ray ray, VOX* vox, 
                   out float t, 
                   out vec3i index,
                   ref Vec!vec3i visitedVoxels)
{    
    int W = vox.width;
    int He = vox.height;
    int De = vox.depth;

    float t_entry;

    vec4f A = vec4f(0, 0, 0,0);
    vec4f B = vec4f(W, 0, 0,0);
    vec4f C = vec4f(0, He, 0,0);
    vec4f D = vec4f(W, He, 0,0);

    vec4f E = vec4f(0, 0, De,0);
    vec4f F = vec4f(W, 0, De,0);
    vec4f G = vec4f(0, He, De,0);
    vec4f H = vec4f(W, He, De,0);

    // Is the ray inside the VOX?
    if (box3f(vec3f(0, 0, 0), vec3f(W, He, De)).contains(ray.orig))
    {
        return false; // Do not manage this case
    }
    else
    {
        // Does it hit ABCD?
       
        // Try to find the entry point and exit point inside the voxel.
        float tmp_u, tmp_v;

        enum int POSX = 0, NEGX = 1, POSY = 2, NEGY = 3, POSZ = 4, NEGZ = 5;

        bool[6] shouldTest;
        bool[6] hit;
        float[6] distance = [FLT_MAX, FLT_MAX, FLT_MAX, FLT_MAX, FLT_MAX, FLT_MAX];

        vec4f rayDir = vec4f(ray.dir.x, ray.dir.y, ray.dir.z, 0.0f);
        vec4f rayOrig = vec4f(ray.orig.x, ray.orig.y, ray.orig.z, 0.0f);

        shouldTest[POSX] = (ray.orig.x > vox.width)  ^ (ray.dir.x >= 0);
        shouldTest[NEGX] = (ray.orig.x < 0)          ^ (ray.dir.x <= 0);
        shouldTest[POSY] = (ray.orig.y > vox.height) ^ (ray.dir.y >= 0);
        shouldTest[NEGY] = (ray.orig.y < 0)          ^ (ray.dir.y <= 0);
        shouldTest[POSZ] = (ray.orig.z > vox.depth)  ^ (ray.dir.z >= 0);
        shouldTest[NEGZ] = (ray.orig.z < 0)          ^ (ray.dir.z <= 0);

        if (shouldTest[POSX]) hit[POSX] = _mm_intersectQuad(rayOrig, rayDir, B, D, F, distance[POSX], tmp_u, tmp_v);
        if (shouldTest[NEGX]) hit[NEGX] = _mm_intersectQuad(rayOrig, rayDir, A, C, E, distance[NEGX], tmp_u, tmp_v);
        if (shouldTest[POSY]) hit[POSY] = _mm_intersectQuad(rayOrig, rayDir, D, C, H, distance[POSY], tmp_u, tmp_v);
        if (shouldTest[NEGY]) hit[NEGY] = _mm_intersectQuad(rayOrig, rayDir, A, B, E, distance[NEGY], tmp_u, tmp_v);
        if (shouldTest[POSZ]) hit[POSZ] = _mm_intersectQuad(rayOrig, rayDir, F, H, E, distance[POSZ], tmp_u, tmp_v);
        if (shouldTest[NEGZ]) hit[NEGZ] = _mm_intersectQuad(rayOrig, rayDir, A, C, B, distance[NEGZ], tmp_u, tmp_v);


        // find the shortest 2 distances
        int numHits = 0;
        float shortestDist = float.infinity;
        float shortestDist2 = float.infinity;
        foreach(n; 0..6)
        {
            if (hit[n]) 
            {
                numHits += 1;
                float d = distance[n];
                assert(isFinite(d));
                if (d < shortestDist)
                {
                    shortestDist2 = shortestDist;
                    shortestDist = d;
                }
                else if (d < shortestDist2)
                {
                    shortestDist2 = d;
                }
            }
        }

        if (numHits < 2)//!= 2)
            return false; // degenerate case, don't bother
        assert(isFinite(shortestDist));
        assert(isFinite(shortestDist2));

        shortestDist += 1e-6f;
        shortestDist2 -= 1e-6f;

        vec3f pointEntry = ray.progress(shortestDist);
        vec3f pointExit = ray.progress(shortestDist2); 
        

        voxelTraversal(pointEntry, pointExit, vox, visitedVoxels);

        foreach(vec3i ind; visitedVoxels[])
        {
            if (vox.voxel(ind.x, ind.y, ind.z).a != 0)
            {
                index = ind;
                t = 0; // TODO
                return true;
            }
        }

        return false; // All traversed voxels are fully-transparent
    }
}



/**
* @brief returns all the voxels that are traversed by a ray going from start to end
* @param start : continous world position where the ray starts
* @param end   : continous world position where the ray end
* @return vector of voxel ids hit by the ray in temporal order
*
* J. Amanatides, A. Woo. A Fast Voxel Traversal Algorithm for Ray Tracing. Eurographics '87
*/


void voxelTraversal(vec3f rayStart, 
                    vec3f rayEnd, 
                    VOX* vox,
                    ref Vec!vec3i visitedVoxels) nothrow @nogc
{
    visitedVoxels.clearContents();


    // This id of the first/current voxel hit by the ray.
    // Using floor (round down) is actually very important,
    // the implicit int-casting will round up for negative numbers.
    vec3i current_voxel = vec3i( cast(int)fast_floor(rayStart.x),
                                 cast(int)fast_floor(rayStart.y),
                                 cast(int)fast_floor(rayStart.z) );

    // The id of the last voxel hit by the ray.
    // TODO: what happens if the end point is on a border?
    vec3i last_voxel = vec3i( cast(int)fast_floor(rayEnd.x),
                              cast(int)fast_floor(rayEnd.y),
                              cast(int)fast_floor(rayEnd.z) );

    static bool validCoord(VOX* vox, vec3i ind)
    {
        return ind.x > 0 && ind.y > 0 && ind.z > 0
        && ind.x < vox.width && ind.y < vox.height && ind.z < vox.depth;
    }

    vec3f ray = rayEnd - rayStart;

    // In which direction the voxel ids are incremented.
    immutable int stepX = (ray[0] >= 0) ? 1:-1; // correct
    immutable int stepY = (ray[1] >= 0) ? 1:-1; // correct
    immutable int stepZ = (ray[2] >= 0) ? 1:-1; // correct

    alias FloatP = double;

    // Distance along the ray to the next voxel border from the current position (tMaxX, tMaxY, tMaxZ).
    FloatP next_voxel_boundary_x = (current_voxel[0]+stepX); // correct
    FloatP next_voxel_boundary_y = (current_voxel[1]+stepY); // correct
    FloatP next_voxel_boundary_z = (current_voxel[2]+stepZ); // correct

    // tMaxX, tMaxY, tMaxZ -- distance until next intersection with voxel-border
    // the value of t at which the ray crosses the first vertical voxel boundary
    FloatP tMaxX = (ray[0]!=0) ? (next_voxel_boundary_x - rayStart[0])/ray[0] : FloatP.max;
    FloatP tMaxY = (ray[1]!=0) ? (next_voxel_boundary_y - rayStart[1])/ray[1] : FloatP.max;
    FloatP tMaxZ = (ray[2]!=0) ? (next_voxel_boundary_z - rayStart[2])/ray[2] : FloatP.max;

    // tDeltaX, tDeltaY, tDeltaZ --
    // how far along the ray we must move for the horizontal component to equal the width of a voxel
    // the direction in which we traverse the grid
    // can only be FLT_MAX if we never go in that direction
    FloatP tDeltaX = (ray[0]!=0) ? 1.0f/ray[0]*stepX : FloatP.max;
    FloatP tDeltaY = (ray[1]!=0) ? 1.0f/ray[1]*stepY : FloatP.max;
    FloatP tDeltaZ = (ray[2]!=0) ? 1.0f/ray[2]*stepZ : FloatP.max;

    vec3i diff = vec3i(0,0,0);
    bool neg_ray=false;
    if (current_voxel[0]!=last_voxel[0] && ray[0]<0) { diff[0]--; neg_ray=true; }
    if (current_voxel[1]!=last_voxel[1] && ray[1]<0) { diff[1]--; neg_ray=true; }
    if (current_voxel[2]!=last_voxel[2] && ray[2]<0) { diff[2]--; neg_ray=true; }

    if (validCoord(vox, current_voxel))
        visitedVoxels.pushBack(current_voxel);

    if (neg_ray) 
    {
        current_voxel+=diff;
        if (validCoord(vox, current_voxel))
            visitedVoxels.pushBack(current_voxel);
    }
    int iter = 0;

    while(last_voxel != current_voxel) 
    {
        if (tMaxX < tMaxY)
        {
            if (tMaxX < tMaxZ) 
            {
                current_voxel[0] += stepX;
                tMaxX += tDeltaX;
            } 
            else 
            {
                current_voxel[2] += stepZ;
                tMaxZ += tDeltaZ;
            }
        } 
        else 
        {
            if (tMaxY < tMaxZ) 
            {
                current_voxel[1] += stepY;
                tMaxY += tDeltaY;
            } 
            else 
            {
                current_voxel[2] += stepZ;
                tMaxZ += tDeltaZ;
            }
        }
        if (validCoord(vox, current_voxel))
            visitedVoxels.pushBack(current_voxel);
        else if (iter > 3)
        {
            break;
        }
        iter++;
    }
}


@nogc bool _mm_intersectQuad(vec4f orig,
                             vec4f dir, 
                             vec4f A, vec4f B, vec4f C, out float t, out float u, out float v) pure nothrow
{
    __m128 mmA = _mm_loadu_ps(A.ptr);
    __m128 mmB = _mm_loadu_ps(B.ptr);
    __m128 mmC = _mm_loadu_ps(C.ptr);
    __m128 mmOrig = _mm_loadu_ps(orig.ptr);
    __m128 mmDir = _mm_loadu_ps(dir.ptr);
    __m128 edge1 = mmB - mmA;
    __m128 edge2 = mmC - mmA;
    __m128 mmpvec = _mm_crossproduct_ps(mmDir, edge2);

    float det = _mm_dot_ps(edge1, mmpvec);
    if (fast_fabs(det) < float.epsilon)
        return false; // no intersection

    float invDet = 1 / det;

    // calculate distance from triangle.a to ray origin
    __m128 tvec = mmOrig - mmA;

    // calculate U parameter and test bounds
    u = _mm_dot_ps(tvec, mmpvec) * invDet;
    if (u < 0 || u > 1)
        return false;

    // prepare to test V parameter
    __m128 qvec = _mm_crossproduct_ps(tvec, edge1);

    // calculate V parameter and test bounds
    v = _mm_dot_ps(mmDir, qvec) * invDet;
    if (v < 0.0 || v > 1.0)
        return false;

    // calculate t, ray intersects triangle
    t = _mm_dot_ps(edge2, qvec) * invDet;
    return true;
}

// Note: .w element is undefined
package __m128 _mm_crossproduct_ps(__m128 a, __m128 b) pure nothrow @nogc
{
    enum ubyte SHUF1 = _MM_SHUFFLE(3, 0, 2, 1);
    enum ubyte SHUF2 = _MM_SHUFFLE(3, 1, 0, 2);
    return _mm_sub_ps(
                      _mm_mul_ps(_mm_shuffle_ps!SHUF1(a, a), _mm_shuffle_ps!SHUF2(b, b)), 
                      _mm_mul_ps(_mm_shuffle_ps!SHUF2(a, a), _mm_shuffle_ps!SHUF1(b, b))
                      );
}

package float _mm_dot_ps(__m128 a, __m128 b) pure nothrow @nogc
{
    __m128 m = a * b;
    return m.array[0] + m.array[1] + m.array[2] + m.array[3];
}