package main

import "core:fmt"
import "core:os"
import "core:math"
import "core:strings"
import "core:math/rand"
import phos ".."

main :: proc() {
	Iteration :: 1000000
	Size :: 512
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

	knowList : [dynamic; Size * 2]phos.Handle

	for i in 0..<Iteration {
		switch rand.uint_max(200) {
			case 0..<100: // Add
				fmt.println("-- ADD", i)
				h := phos.add(&players)
				assert(h.idx != 0, fmt.tprintln("[Add] Invalid Handle:", h))
				fmt.println(h)
				append(&knowList, h)
				break
			case 100..<200: // Remove
				fmt.println("-- REM", i)
				if len(knowList) > 0 {
					h := pop(&knowList)
					fmt.println(h)
					if players.list[h.idx-1].gen != h.gen {
						fmt.println("Handle Gen is unequal")
						h.gen = players.list[h.idx-1].gen
					}
					assert(phos.is_valid(&players,h), fmt.tprintln("[Remove] Value is Invalid:",h,"\nKnow List:",knowList))
					assert(phos.remove(&players,h), fmt.tprintln("[Remove] Error",h))
				} else {
					fmt.println("Skipped by Len == 0")
				}
				break
		}
	}
}
