package main

import "core:time"
import "core:fmt"
import "core:os"
import "core:math"
import "core:strings"
import "core:math/rand"
import "core:math/bits"
import "core:container/handle_map"
import "core:terminal/ansi"
import phos ".."

main :: proc() {
	Iteration :: 100000
	IterationLoop :: 1000
	Size :: 1024 * 10
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

	MIDDLE :: 101

	add, rem : uint
	clock_add, clock_rem : time.Stopwatch
	time_add, time_rem : time.Duration
	
	fmt.println("[Add and Rem]")
	for i in 0..<Iteration {
		switch rand.uint_max(200) {
			case 0..<MIDDLE: // Add
				if false { //See if History has empty slots
					fmt.print("History: ")
					for n,n_i in players.history {
						if players.list[n].idx != phos.NULL_IDX {
							fmt.print(ansiColor(ansi.FG_GREEN), n, ",", sep="")
						} else {
							fmt.print(ansiColor(ansi.FG_RED), n, ",", sep="")
						}
					}; fmt.println(ansiColor(ansi.RESET))
				}

				// fmt.println("-- ADD", i)
				time.stopwatch_start(&clock_add)
				h,_ := phos.add(&players)
				time.stopwatch_stop(&clock_add)
				assert(h.idx != phos.NULL_IDX, fmt.tprintln("[Add] Invalid Handle:", h))
				// fmt.println(h)
				append(&knowList, h)
				add += 1
				time_add += time.stopwatch_duration(clock_add)
				time.stopwatch_reset(&clock_add)
				break
			case MIDDLE..<200: // Remove
				// fmt.println("-- REM", i)
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
					time.stopwatch_start(&clock_rem)
					res := phos.remove(&players,h)
					time.stopwatch_stop(&clock_rem)
					assert(res, fmt.tprintln("[Remove] Error",h))
					rem += 1
				} else {
					// fmt.println("Skipped by Len == 0")
				}
				time_rem += time.stopwatch_duration(clock_rem)
				time.stopwatch_reset(&clock_rem)
				break
		}
	}
	// fmt.printf("%#v", players.list[:phos.len(players)])
	time_add, time_rem = time_add/time.Duration(add),time_rem/time.Duration(rem)
	time_total := time_add + time_rem
	fmt.println("Len:",phos.len(players))
	fmt.println("ADD:",add,"Time:",time_add)
	fmt.println("REM:",rem,"Time:",time_rem)
	fmt.println("ADD/REM - Total Time:",time_total)

	
	ansiColor :: proc(color: string) -> string {
		return fmt.tprint(ansi.CSI, color, ansi.SGR, sep="")
	}
	fmt.print("History: ")
	for n,n_i in players.history {
		if players.list[n].idx != phos.NULL_IDX {
			fmt.print(ansiColor(ansi.FG_GREEN), n, ",", sep="")
		} else {
			fmt.print(ansiColor(ansi.FG_RED), n, ",", sep="")
		}
	}; fmt.println(ansiColor(ansi.RESET))


	fmt.println("[Len]")
	clock_len : time.Stopwatch
	time_len : time.Duration
	for i in 0..<Iteration {
		time.stopwatch_start(&clock_len)
		phos.len(players)
		time.stopwatch_stop(&clock_len)
		time_len += time.stopwatch_duration(clock_len)
		time.stopwatch_reset(&clock_len)
	}
	time_len = time_len/Iteration
	fmt.println("Time:",time_len/Iteration)
	
	fmt.println("[Looping]")
	fmt.println("length:",phos.len(players))
	
	clock_loop : time.Stopwatch
	time_loop : time.Duration
	for i in 0..<100 {
		time.stopwatch_start(&clock_loop)
		for i in 0..<phos.len(players) {
			if phos.is_valid(&players, players.list[i].handle) {
				players.list[i].data.damage += 1
			}
		}
		time.stopwatch_stop(&clock_loop)
		time_loop += time.stopwatch_duration(clock_loop)
		time.stopwatch_reset(&clock_loop)
	}
	fmt.println("Time:",time_loop/Iteration)
}
