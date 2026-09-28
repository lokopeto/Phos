<div>
	<img width="230" alt="logo" align="left" src="https://github.com/lokopeto/assets/blob/master/Phos/Phos.png"/>
	<h3>Phos - Fast and Simple Static Handle Map</h3>
</div>

No pointer arithmetic! array indexing Only. Inspired by the Ben Kenwright paper [Fast Efficient Fixed-Size Memory Pool](https://arxiv.org/abs/2210.16471) 
<p><br></p>
<p><br></p>
<p><br></p>

## Tests
```bash
odin run test -o:speed
```
There is a stress test using Raylib for a graphical representation of the data:
```bash
odin run test_raylib -o:speed
```

## How to Use It
First, create a HandleBox,
The HandleBox will pre allocate a list within a specified size
```Odin
entities := phos.create(
	struct{ pos: [3]f32 }, // $T: typeid
	// The type of the data of the array
	1024, // size: uint
	// The size of the array
	//leftovers : uint = 4 
	// Dont mess with that value unless you know what you are doing
)
```
Use that to claim a handle for use,
e = The handle that is claimed
e_data = Pointer to the data
```Odin
entity, entity_data := phos.add(
	&entities //box: ^HandleBox($T)
)
```
Phos will silently fail if add is invalid
Use this if you want to verify
```Odin
valid := phos.is_valid(
	&entities, //box: ^HandleBox($T), 
	entity //h: Handle
)
```
Phos will not do iteration for you!
It has everything you need, here is a example:
```Odin
for e in entities.list[:phos.len(&entities)] {
	if phos.is_valid(&entities,e) {
		// e.data has the data!
	}
}
```
Use this to remove a handle and reset the data

**OBS: Phos will NOT realocate the data, it will just reset all to 0, any heap allocation will LEAK, you have to manually free before removing it!**
```Odin
removed := phos.remove(
	&entities, //box: ^HandleBox($T), 
	entity //h: Handle
)
```
In case you want to delete the entire HandleBox, 
you can use this, it will free from the memory

**OBS: any heap allocation will LEAK, you have to manually free before removing it!**
```Odin
phos.delete(
	&entities //box: ^HandleBox($T), 
)
```
*As always.. Have Fun!*
