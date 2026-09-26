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


	Iteration :: 100
	Size :: 1024 * 10

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

	knowList : [dynamic; Size]phos.Handle

	MIDDLE :: 110
	Space :: 8
	fmt.println("[Add and Rem]")
	r.SetTargetFPS(90)
	for !r.WindowShouldClose() {
		r.BeginDrawing()
		r.ClearBackground({0,00,00,255})
		r.DrawFPS(0, WinSize.y - 20)
		
		for x in 0..<Size {
			// fmt.println(players.list[x].idx == phos.NULL_IDX)
			color := players.list[x].idx == phos.NULL_IDX ? r.Color{100,100,70,255} : r.Color{0,120,255,255}
			y := int(f32(x * Space) / f32(WinSize.x)) * Space
			x := (x * Space) % int(WinSize.x)
			
			r.DrawRectangleV({f32(x),f32(y)}, {Space-1,Space-1}, color)
		}


		for i in 0..<Iteration {
			switch rand.uint_max(200) {
				case 0..<MIDDLE: // Add
					// fmt.println("-- ADD", i)
					h,_ := phos.add(&players)
					assert(h.idx != phos.NULL_IDX, fmt.tprintln("[Add] Invalid Handle:", h))
					// fmt.println(h)
					append(&knowList, h)
				case MIDDLE..<200: // Remove
					if len(knowList) > 0 {
						h := pop(&knowList)
						if max(0,players.list[h.idx].gen) != h.gen {
							// fmt.println("Handle Gen is unequal")
							h.gen = players.list[h.idx].gen
						}
						assert(phos.is_valid(&players,h), fmt.tprintln(
								"[Remove] Value is Invalid:",h,"/",players.list[h.idx].handle,"\nKnow List:",knowList
							)
						)
						res := phos.remove(&players,h)
						assert(res, fmt.tprintln("[Remove] Error",h))
					}
			}
		}


		r.EndDrawing()
	}
	r.CloseWindow()

}
