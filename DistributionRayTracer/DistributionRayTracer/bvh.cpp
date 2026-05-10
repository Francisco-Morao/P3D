#include "rayAccelerator.h"
#include "macros.h"

using namespace std;

BVH::BVHNode::BVHNode(void) {}

void BVH::BVHNode::setAABB(AABB& bbox_) { this->bbox = bbox_; }

void BVH::BVHNode::makeLeaf(unsigned int index_, unsigned int n_objs_) {
	this->leaf = true;
	this->index = index_; 
	this->n_objs = n_objs_; 
}

void BVH::BVHNode::makeNode(unsigned int left_index_) {
	this->leaf = false;
	this->index = left_index_; 
}


BVH::BVH(void) {}

int BVH::getNumObjects() { return objects.size(); }


void BVH::Build(vector<Object *> &objs) {

	BVHNode *root = new BVHNode();

	Vector min = Vector(FLT_MAX, FLT_MAX, FLT_MAX), max = Vector(-FLT_MAX, -FLT_MAX, -FLT_MAX);
	AABB world_bbox = AABB(min, max);

	for (Object* obj : objs) {
		AABB bbox = obj->GetBoundingBox();
		world_bbox.extend(bbox);
		objects.push_back(obj);
	}
	world_bbox.min.x -= EPSILON; world_bbox.min.y -= EPSILON; world_bbox.min.z -= EPSILON;
	world_bbox.max.x += EPSILON; world_bbox.max.y += EPSILON; world_bbox.max.z += EPSILON;
	root->setAABB(world_bbox);
	nodes.push_back(root);
	build_recursive(0, objects.size(), root); // -> root node takes all the objects
}

void BVH::build_recursive(int left_index, int right_index, BVHNode *node) {

	//right_index, left_index and split_index refer to the indices in the objects vector
	// do not confuse with left_nodde_index and right_node_index which refer to indices in the nodes vector. 
	// node.index can have a index of objects vector or a index of nodes vector
	
	if ((right_index - left_index) < Threshold) {
		node->makeLeaf(left_index, right_index);
		return;
	}
	Comparator comp;
	
	Vector distance = node->getAABB().max - node->getAABB().min;
	int axis = 0; // x-axis

	if (distance.y > distance.x) 
		axis = 1; // y-axis
	if (distance.z > distance.getAxisValue(axis))
		axis = 2; // z-axis

	comp.dimension = axis;

	std::sort(objects.begin() + left_index, objects.begin() + right_index, comp);
	

	// mean com o centro dos centroids????
	int mid = left_index + (right_index - left_index) / 2;
	float partition = (objects[mid]->getCentroid().getAxisValue(comp.dimension) +
				objects[mid - 1]->getCentroid().getAxisValue(comp.dimension)) / 2.0f;

	int split_index = -1;
	Vector min = Vector(FLT_MAX, FLT_MAX, FLT_MAX);
	Vector max = Vector(-FLT_MAX, -FLT_MAX, -FLT_MAX);
	AABB left_bbox = AABB(min, max), right_bbox = AABB(min, max);
	
	for (int i = left_index; i < right_index; i++) {
		if (split_index == -1) {
			left_bbox.extend(objects[i]->GetBoundingBox());
			if (objects[i]->getCentroid().getAxisValue(comp.dimension) >= partition) {
				split_index = i;
			}
		}
		else {
			right_bbox.extend(objects[i]->GetBoundingBox());
		}
	}

	// Vector min = Vector(FLT_MAX, FLT_MAX, FLT_MAX), max = Vector(-FLT_MAX, -FLT_MAX, -FLT_MAX);
	// AABB left_bbox = AABB(min, max);
	// AABB right_bbox = AABB(min, max);
	// for (int i = left_index; i < split_index; i++) {
	// 	left_bbox.extend(objects[i]->GetBoundingBox());
	// }
	// for (int i = split_index; i < right_index; i++) {
	// 	right_bbox.extend(objects[i]->GetBoundingBox());
	// }

	if (split_index == -1) {
		split_index = right_index;
	}

	if (split_index == left_index || split_index == right_index) {
		node->makeLeaf(left_index, right_index);
		return;
	}

	node->makeNode(nodes.size()); // left child index in nodes vector

	BVHNode* left = new BVHNode();
	BVHNode* right = new BVHNode();

	left_bbox.min -= EPSILON;
	left_bbox.max += EPSILON;
	right_bbox.min -= EPSILON;
	right_bbox.max += EPSILON;
	
	left->setAABB(left_bbox);
	right->setAABB(right_bbox);

	nodes.push_back(left);
	nodes.push_back(right);

	build_recursive(left_index, split_index, left);
	build_recursive(split_index, right_index, right);
}

bool BVH::Traverse(Ray& ray, Object** hit_obj, HitRecord& hitRec) {
	float tmp;
	bool hit = false;
	stack<StackItem> hit_stack;
	HitRecord rec;   //rec.isHit initialized to false and rec.t initialized with FLT_MAX

	BVHNode* currentNode = nodes[0];

	//PUT YOUR CODE HERE

	return hit;
		
}

bool BVH::Traverse(Ray& ray) {  //shadow ray with length
	float tmp;
	stack<StackItem> hit_stack;
	HitRecord rec;

	double length = ray.direction.length(); //distance between light and intersection point
	ray.direction.normalize();


	return false;  //no primitive intersection	
}		
