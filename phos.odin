package phos

import "base:runtime"
import "core:mem/virtual"
import "core:math/bits"
// import "core:fmt"

NULL_IDX :: bits.UINT_MAX

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
	history: [128]uint,
	// free: uint,
	// allocated: uint,
	
	list: #soa[]HandleData(T)
}

// Make a "Handle Box" - A list of Handles with data and a head for internal use.
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

	err = virtual.arena_init_static(&d.arena, sz+l_sz, sz); err or_return
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
	for &l in d.list {l.idx = NULL_IDX}
	return
}
// Delete the HandleBox
delete :: proc(data: ^HandleBox($T)) {
	virtual.arena_free_all(&data.arena)
	delete(data)
}
// Get the length of claimed handles
// good for iteration over the list
len :: proc(box: HandleBox($T)) -> (high: int) {
	for v,i in box.list {
		if v.idx != NULL_IDX {
			high = i
		}
	}
	return
}
// Add and get a Handle on a Handle Box
// If idx is NULL_IDX - max(uint) - there is no empty slot
add :: proc(box: ^HandleBox($T)) -> (h: Handle, ptr: ^T) {
	defer h.idx = NULL_IDX

	// First Validation
	// Verify Index in Head
	// fmt.println("First Validation")
	if box.list[box.head].idx == NULL_IDX {
		h = { box.head, box.list[box.head].gen }

		box.list[h.idx].idx = h.idx
		ptr = &box.list[h.idx].data
		box.history = history_rem(box.history, box.head)
		return
	}

	// Second Validation
	// Verify Index One Offset Around
	// fmt.println("Second Validation")
	head_clampled := [?]uint{box.head==0?0:box.head-1, box.head+1}
	// fmt.println(head_clampled, box.head)
	second_pass : bool
	if head_clampled.x != 0 && box.list[head_clampled.x].idx == NULL_IDX {
		second_pass = true
		box.head = box.head==0 ? 1 : box.head-1
		h = { head_clampled.x, box.list[box.head].gen }
	} else if head_clampled.y < box.size && box.list[head_clampled.y].idx == NULL_IDX {
		second_pass = true
		box.head = box.head==box.size ? box.size>>2 : box.head+1
		h = { head_clampled.y, box.list[box.head].gen }
	}
	if second_pass {
		box.list[box.head].idx = h.idx
		ptr = &box.list[box.head].data		
		box.history = history_rem(box.history, box.head)
		return
	}

	//Third Validation
	//Search Thru History
	// fmt.println("Third Validation")
	MAX_SEARCH :: 10
	MAX_SEARCH_DIV :: MAX_SEARCH >> 2
	last : uint = NULL_IDX
	for n,n_i in box.history {
		if last == n { continue }
		// fmt.print(n,",",sep="")
		for i in 0..<MAX_SEARCH {
			n_s := n+uint(i-MAX_SEARCH_DIV)
			// fmt.println(n_s)
			if box.list[n_s].idx == NULL_IDX {
				box.head = n_s
				box.list[box.head].idx = n_s
				h = {n_s, box.list[box.head].gen}
				box.history = history_rem(box.history, n_s)
				return
			}
		}
		last = uint(n)
	}

	//Fourth Validation
	//Linear Search
	// fmt.println("Fourth Validation")
	idx_list,_ := soa_unzip(box.list)
	for n,i in idx_list[:] {
		if n.idx == NULL_IDX {
			box.head = uint(i)
			box.list[box.head].idx = box.head
			h = {box.head, box.list[box.head].gen}
			box.history = history_rem(box.history, box.head)
			return
		}
	}
	return
}
// Add handle to a specified index, for more advanced use.
// Does validation on his own
add_indexed :: proc(box: ^HandleBox($T), index: uint) -> (Handle,^T) {
	if box.list[h.idx].idx != NULL_IDX {
		box.list[h.idx].idx = h.idx
		box.list[h.idx].data = {}
		return box.list[h.idx].handle, &box.list[h.idx].data
	} else {return {NULL_IDX, 0}, nil}
}
// Remove Handle from HandleBox
remove :: proc(box: ^HandleBox($T), h: Handle) -> bool {
	is_valid(box,h) or_return
	box.head = h.idx
	box.list[h.idx] = {
		handle = {
			gen = box.list[h.idx].handle.gen + 1,
			idx = NULL_IDX,
		},
		data = {}
	}
	
	box.history = history_add(box.history, h.idx)
	return true
}
// Verify if Handle exist on the HandleBox
@(require_results)
is_valid :: proc(box: ^HandleBox($T), h: Handle) -> bool {
	when ODIN_DEBUG {
		assert(h.idx != NULL_IDX, "Uninitialized Handle")
	}
	return box.list[h.idx].handle == h
}
// Get a pointer data underneath the Handle
get_data_ptr :: proc(box: ^HandleBox($T), h: Handle) -> ^T {
	is_valid(b,h)
	return &box.list[h.idx].data
}
// Get a static data underneath the Handle
get_data :: proc(box: ^HandleBox($T), h: Handle) -> T {
	is_valid(b,h)
	return box.list[h.idx].data
}



@(require_results, private)
history_add :: proc "contextless" (history: [$N]uint, num: uint) -> (res: [N]uint) {
	for n, n_i in history {
		if n == num {res = history; return}
		if n_i+1 >= N {break}
		res[min(1+n_i,N)] = n
	}
	if res[1] != num && history[N-1] != num do res[0] = num
	return
}
@(require_results, private)
history_rem :: proc "contextless" (history: [$N]uint, num: uint) -> (res: [N]uint) {
	idx : int
	history := history
	// fmt.println("His Before:",history, num)
	for i in 0..<N {
		if history[i] == num {
			// fmt.println(history[i:],"\n", history[i+1:], num, i)
			copy(history[i:], history[i+1:])
			break
		}
	}
	
	if history[N-2] != num && history[0] != num do history[N-1] = num
	// fmt.println("\nHis After:",history, num)
	return history
}
