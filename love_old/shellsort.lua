--[==[
// shell sort is insertion sort over a gap
// it pushes large values towards the end and small values towards the start
// the last run is pure insertion sort on a nearly sorted list, insertion sort's best case scenario
void shellSort(int* array, int length){
    // create the shell, the gap between values, initial length is length/2. Stop when the shell is lower than 1 
    for(int shell = length>>1; shell > 0; shell = shell>>1){
        // iterate through the list starting at the same index as the shell, as all others before this index cannot be swapped due to the shell
        for( int i = shell; i < length; i++){
            // walk is used to push values back as far as they can be.
            // the condition for the for loop needs to check for both the swap condition (array[...] < array[...]) and to check if the second value across the shell is a valid index (... >= 0)
            for(int walk = 0; (i-walk-shell) >= 0 && array[i-walk] < array[i-walk-shell]; walk -= shell){
            // swap the values of the list elements that are out of order
            std::swap(array[i-walk], array[i-walk-shell]);
            }
        }
    }
}
]==]

return function(self)
  local shell = math.floor(#self / 2)
  while shell > 0 do
    for i = shell, #self do
      local walk = 0
      while (i - walk - shell) > 0 and self[i - walk] < self[i - walk - shell] do
        self[i - walk], self[i - walk - shell] = self[i - walk - shell], self[i - walk]
        walk = walk + shell
      end
    end
    shell = math.floor(shell / 2)
  end
  return self
end
