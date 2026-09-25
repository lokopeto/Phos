package phos

import "base:runtime"
import "core:mem/virtual"
import "core:fmt"
import "core:os"
import "core:math"
import "core:strings"

Handle :: struct #simple{
	idx : uint,
	gen : uint,
}

HandleData :: struct($T: typeid) {
	using handle : Handle,
	data : T
}

HandleBox :: struct($T: typeid){
	allocator : runtime.Allocator,
	arena : virtual.Arena,
	size: uint,
	leftovers: uint,
	size_total: uint,
	leftovers_total: uint,

	head: uint,
	history_rem: [dynamic;128]uint,
	// free: uint,
	// allocated: uint,
	
	list: #soa[]HandleData(T)
}

// Make a array from a type and a size.
// Leftovers will be used for the creation of the arena, not on the array,
// also, he's added to the size (size + leftovers).
// The size is minus one off compared to the array size
@(require_results)
create :: proc(
	$T: typeid,
	#any_int size: uint, 
	#any_int leftovers : uint = 4
) -> (
	d: HandleBox(T), 
	err: virtual.Allocator_Error
) {
	sz, l_sz := size * size_of(T), leftovers * size_of(T)

	err = virtual.arena_init_static(&d.arena, l_sz, sz); err or_return
	allocator := virtual.arena_allocator(&d.arena)
	d = {
		size = size,
		leftovers = leftovers,

		size_total = sz,
		leftovers_total = l_sz,

		// free = size,
		allocator = allocator
	}
	d.list = make(#soa[]HandleData(T), sz, d.allocator)
	return
}
delete :: proc(data: ^HandleBox($T)) {
	virtual.arena_free_all(&data.arena)
	delete(data)
}
len :: proc() {}
// If idx and gen is 0, there is no empty slot
add :: proc(box: ^HandleBox($T)) -> (h: Handle) {
	// First Validation
	// Verify Index in Head
	fmt.println("First Validation")
	if box.list[box.head].idx == 0 {
		box.list[box.head].idx = 1+box.head
		h.idx = 1+box.head
		box.history_add = history_add(box.history_add, 1+box.head)
		return
	}

	// Second Validation
	// Verify Index One Offset Around
	fmt.println("Second Validation")
	head_clampled := [?]uint{box.head==0?0:box.head-1, box.head+1}
	fmt.println(head_clampled, box.head)
	if head_clampled.x != 0 && box.list[head_clampled.x].idx == 0 {
		box.head = box.head==0 ? 1 : box.head-1
		box.list[box.head].idx = head_clampled.x+1
		h.idx = head_clampled.x+1
		box.history_add = history_add(box.history_add, box.head)
		fmt.println(box.head)
		return
	} else if head_clampled.y < box.size && box.list[head_clampled.y].idx == 0 {
		box.head = box.head==box.size ? box.size>>2 : box.head+1
		box.list[box.head].idx = head_clampled.y+1
		h.idx = head_clampled.y+1
		box.history_add = history_add(box.history_add, box.head)
		fmt.println(box.head)
		return
	}

	//Third Validation
	//Search Thru History
	fmt.println("Third Validation")
	for n,n_i in box.history_rem {
		fmt.print(n,",",sep="")
		head := n==0?0:n-1
		if box.list[head].idx == 0 {
			box.head = head
			box.list[box.head].idx = n
			h.idx = n
			box.history_add = history_add(box.history_add, box.head)
			return
		}
	}
	// //Fourth Validation
	// //Search Thru Array mult by 2
	// for v,k in N {

	// }
	return
}
remove :: proc(box: ^HandleBox($T), handle: Handle) -> bool {
	is_valid(box, handle) or_return
	idx := handle.idx-1
	box.head = box.list[idx].idx-1
	box.list[idx].gen += 1
	box.list[idx].idx = 0
	box.history_rem = history_add(box.history_rem, handle.idx)
	return true
}
is_valid :: proc(box: ^HandleBox($T), handle: Handle) -> bool {
	assert(handle.idx != 0, "Uninitialized Handle")
	idx := handle.idx-1
	fmt.println(box.list[idx].handle == handle, idx)
	fmt.println(box.list[idx].handle,"-",handle)
	return box.list[idx].handle == {handle.idx,handle.gen}
}

// @(require_results)
// history_add :: proc(history: [$N]uint, num: uint) -> (res: [N]uint) {
// 	for n, n_i in history {
// 		if n == num {res = history;return}
// 		if n_i+1 >= N {break}
// 		res[min(1+n_i,N)] = n
// 	}
// 	res[0] = num
// 	return
// }
// @(require_results)
// history_rem :: proc(history: [$N]uint, num: uint) -> (res: [N]uint) {
// 	for n, n_i in history {
// 		if n == num {res = history;return}
// 		if n_i == 0 {continue}
// 		res[min(1-n_i,N)] = n
// 	}
// 	res[0] = num
// 	return
// }
