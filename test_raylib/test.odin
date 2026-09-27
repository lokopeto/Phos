package main

import "core:c"
import "core:time"
import "core:fmt"
import "core:os"
import "core:math"
import "core:strings"
import "core:math/rand"
import "core:math/bits"
import "core:container/handle_map"
import "core:terminal/ansi"
import r "vendor:raylib"
import phos ".."

main :: proc() {
	WinSize :: [?]c.int{1280, 720}
	r.InitWindow(WinSize.x, WinSize.y, "Phos Test")	
	r.SetWindowState({.WINDOW_RESIZABLE})


	Iteration :: 10000
	Iteration_Remove :: 2
	Size :: 1024 * 20
	MIDDLE :: 180
	Space :: 10

	winDrawRec :=  ([2]c.float{Size,Size} / (cast([2]c.float)WinSize)) / Size
	
	fmt.println(winDrawRec)
	fmt.println(f32(WinSize.y / 2) * winDrawRec.y)

	Player :: struct 	{
		health : uint,
		health_max : uint,
		damage : uint,
		itens : []struct {
			type : enum	{Sword, Bow, Bomb},
			amount : uint
		},
	}
	players, err := phos.create(Player, Size)

	FIXED_UPDATE :: 1.0 / 60
	accum : f32

	fmt.println("[Add and Rem]")
	r.SetTargetFPS(90)
	headlist : [200]uint
	for !r.WindowShouldClose() {
		fmt.println(phos.len(&players), "/", Size)
		assert(phos.len(&players) != -1, "Invalid Len")

		accum += r.GetFrameTime()
		
		r.BeginDrawing()
		r.ClearBackground({0,0,0,255})

		// fmt.println(players.free)
		headlist[0] = players.head
		copy(headlist[1:], headlist[:])
		for x in 0..<Size {
			// fmt.println(players.list[x].idx == phos.NULL_IDX)
			is_valid :=	players.list[x].idx == phos.NULL_IDX
			color := is_valid ? r.Color{70,70,70+u8(u8(x<=phos.len(&players))*70),255} : 
				r.Color{u8(min(u32(players.list[x].gen>=255 * (players.list[x].gen * 2)),255)),120,u8(min(players.list[x].gen >> 2,255)),255}

			coord := x_toCoord(int(x))
			
			r.DrawRectangleV(coord, {Space-1,Space-1}, color)
			if players.claimed + players.free == uint(x) {
				r.DrawRectangleV(coord, {Space-1,Space-1}, {255,80,255,255})
			}
			if players.claimed == uint(x) {
				r.DrawRectangleV(coord, {Space-1,Space-1}, {255,255,80,255})
			}
			if players.head_highest == uint(x) {
				r.DrawRectangleV(coord, {Space-1,Space-1}, {130,100,0,160})
			}
		}
		for x,x_i in headlist {
			coord := x_toCoord(int(x))
			r.DrawRectangleV(coord, {Space-2,Space-2}, {100,200,255,40+u8((len(headlist)-x_i)*4)})
		}
		for x in players.history {
			coord := x_toCoord(int(x))
			r.DrawRectangleLinesEx({coord.x,coord.y,Space-1,Space-1}, 1, {222,222,222,100})
		}

		for {
			if accum > FIXED_UPDATE {
				for i in 0..<Iteration {
					switch rand.uint_max(200) {
						case 0..<MIDDLE: // Add
							// fmt.println("-- ADD", i)
							h,_ := phos.add(&players)
							assert(h.idx != phos.NULL_IDX, fmt.tprintln("[Add] Invalid Handle:", h))
							// fmt.println(h)
						case MIDDLE..<200: // Remove
							for i in 0..<Iteration_Remove {
								// fmt.println(h.idx)
								n := rand.int_max(Size)
								for i in 0..<rand.int_max(50) {
									h := phos.Handle{
										idx = uint(max(0,n - i))
									}; 
									if players.list[h.idx].idx == phos.NULL_IDX do continue
									h.gen = players.list[h.idx].gen
	
									res := phos.remove(&players,h)
									assert(res, fmt.tprintln("[Remove] Error",h))
								}
							}
					}
				}
				accum -= FIXED_UPDATE
			} else {break}
		}
		if r.IsKeyPressed(.SPACE) {
			high : int
			for v,k in players.list {
				if v.idx != phos.NULL_IDX {
					high = k
				}
			}
			
			high_half := high >> 2
			#reverse for h,i in players.list[high_half:high] {
				fmt.println(i)
				if h.idx != phos.NULL_IDX {
					phos.remove(&players,h.handle)
				}
			}
		}

		r.DrawFPS(0, r.GetRenderHeight() - 20)
		r.EndDrawing()
	}
	r.CloseWindow()
	x_toCoord :: proc(x: int) -> [2]c.float {
		return {
			c.float(int(x * Space) % int(r.GetRenderWidth())),
			c.float(int(f32(x * Space) / f32(r.GetRenderWidth())) * Space)
		}
	}
}
