package asx {

  import asx.array.*;  
  import asx.fn.I;
  import asx.object.isA;
  import spectacular.dsl.*;
  import org.hamcrest.*;
  import org.hamcrest.core.*;
  import org.hamcrest.collection.*;
  import org.hamcrest.object.*;

  public function ArraySpecs():void {
    
    describe('asx.array', function():void {
      describe('pluck', function():void {
        it('returns an array of the value of the given field for each item', function():void {
          assertThat(pluck('a bee seady ee effigy'.split(' '), 'length'), equalTo([1, 3, 5, 2, 6]));
        });
        it('follows a chain of fields from a String', function():void {
          assertThat( pluck(
              [{ outer: { middle: { inner: { value: 3 }}}}], 
              'outer.middle.inner.value'),
              equalTo([3]));
        });
        it('follows a chain of fields from an Array', function():void {
          assertThat( pluck(
              [{ outer: { middle: { inner: { value: 3 }}}}], 
              ['outer', 'middle', 'inner', 'value']),
              equalTo([3]))
        });
        it('plucks methods too', function():void {
          assertThat( pluck([1, 10, 100], 'toString().length'), equalTo([1, 2, 3]));
        });
      });

      describe('inject', function():void {
        it('passes the memo and each item individually to the iterator function and return the memo', function():void {
          var memo:Number = 0;
          var values:Array = [1, 2, 3, 4];
          var sum:Function = function(acc:Number, value:Number):Number {
            return acc + value;
          };
          var sumWithAllArgs:Function = function(acc:Number, value:Number, i:int, a:Array):Number {
            return acc + value;
          };
          var sumWithRestArgs:Function = function(acc:Number, value:Number, ...rest):Number {
            return acc + value;
          };

          assertThat(inject(memo, values, sum), equalTo(10));
          assertThat(inject(memo, values, sumWithAllArgs), equalTo(10));
          assertThat(inject(memo, values, sumWithRestArgs), equalTo(10));
        });
      });

      describe('unfold', function():void {
        it('works for simple values', function():void {
          var p:Function = function(n:Number):Boolean { return n > 0; };
          var t:Function = function(n:Number):Number { return n - 2; };
          var i:Function = t;

          assertThat(unfold(10, p, t, i), equalTo([8, 6, 4, 2, 0]));
        });

        it('works for complex values', function():void {
          var parent:Object = { values: [1, 2, 3] };
          var child1:Object = { parent: parent, values: [4, 5, 6] };
          var child2:Object = { parent: child1, values: [7, 8, 9] };

          var predicate  :Function = function(o:Object):Boolean { return o && o.values != null };
          var transformer:Function = function(o:Object):Object { return o.values; };
          var incrementor:Function = function(o:Object):Object { return o.parent; }

          assertThat(unfold(child2, predicate, transformer, incrementor), equalTo([[7, 8, 9], [4, 5, 6], [1, 2, 3]]));
        });
      });

      describe('flatten', function():void {
        it('takes a nested array and return a one dimensional array', function():void {
          assertThat(flatten([1, 2, [3, 4, 5, [6], [7, 8]], 9]), equalTo([1, 2, 3, 4, 5, 6, 7, 8, 9]));
        });
      })

      describe('zip', function():void {
        it('takes arrays arguments and return an array where each entry is an array of the values at that index in the argument arrays', function():void {
          assertThat(zip([1, 2, 3], ['a', 'b', 'c']), 
                     equalTo([[1, 'a'], [2, 'b'], [3, 'c']]));

          assertThat(zip([1, 2, 3], ['a', 'b', 'c'], [true, true, false, true]), 
                     equalTo([[1, 'a', true], [2, 'b', true], [3, 'c', false], [null, null, true]]));
        });
      });

      describe('compact', function():void {
        it('returns an array without null values', function():void {
          assertThat(compact([null]), equalTo([]));
          assertThat(compact([null, null, 3, null]), equalTo([3]));
          assertThat(compact(['toast', 'waffles', null, 'crumpets']), equalTo(['toast', 'waffles', 'crumpets']));
        });
      });

      describe('unique', function():void {
        it('returns an array without duplicate values', function():void {
          assertThat(unique([1, 1, 2, 3, 5]), equalTo([1, 2, 3, 5]));
          assertThat(unique(['one', 'two', 'two', 'two']), equalTo(['one', 'two']));
        });
        
        it('returns an array of items without duplicate field values', function():void {
          var items:Array = [{ id: 1, value: 1 }, { id: 2, value: 1 }, { id: 3, value: 2 }];
          assertThat(unique(items, "value"), array(hasProperty("id", 1), hasProperty("id", 3)));
        });
      });

      describe('partition', function():void {
        it('separates values on the boolean return value of the iterator function', function():void {
          var greaterThan3:Function = function(value:Number):Boolean { return value >3 };

          assertThat(partition([1, 2, 3, 4, 5], greaterThan3), 
                     equalTo([[4, 5], [1, 2, 3]]));
        });
      });

      describe('partitionBy', function():void {
        it('separates values on the numeric return value of the iterator function', function():void {
          var mod3:Function = function(value:Number):int { return value % 3; };

          assertThat(partitionBy([1, 2, 3, 4, 5, 6, 7, 8, 9], mod3),
                     equalTo([[3, 6, 9], [1, 4, 7], [2, 5, 8]]));
        });    
      });

      describe('contains', function():void {
        it('returns true if the array contains the value', function():void {
          assertThat(contains([], 0), equalTo(false));
          assertThat(contains([1, 2, 3], 0), equalTo(false));
          assertThat(contains([1, 2, 3], 3), equalTo(true));
        });
      });

      describe('detect', function():void {
        it('returns the first matching item', function():void {
          var values:Array = [1, 1, 2, 3, 5, 8];
          var finder:Function = function(n:Number, i:int, a:Array):Boolean {
            return n > 4;
          };
          assertThat(detect(values, finder), equalTo(5));
        });
      });
      
      describe('invoke', function():void {
        it('invokes the named method on each item of the array and returns the results', function():void {
          assertThat(invoke([1, 2, 3], 'toString'), equalTo(["1", "2", "3"]));
        });
        it('invokes the named method and passes in arguments', function():void {
          assertThat(invoke([1, 2, 3], 'toString', 2), equalTo(["1", "10", "11"]));
        });
      });
      
      describe('head', function():void {
        it('returns the first item in the array', function():void {
          assertThat(head([2, 1, 0]), equalTo(2));
        });
        
        it('returns null if the array is empty', function():void {
          assertThat(head([]), nullValue());
        });
      });
      
      describe('tail', function():void {
        it('returns an array without the first item', function():void {
          assertThat(tail([2, 1, 0]), equalTo([1, 0]));
        });
        
        it('returns an empty array if length is 0 or 1', function():void {
          assertThat(tail([]), []);
          assertThat(tail([1]), []);
        });
      });
      
      describe('without', function():void {
        it('returns an array without the specified items', function():void {
          var values:Array = [0, 1, 2, 3];
          assertThat(without(values, 2), equalTo([0, 1, 3]));
          assertThat(without(values, 0, 1), equalTo([2, 3]));
        });
      });
      
      describe('random', function():void {
        it('returns a random item from the array', function():void {
          var values:Array = [1, 2, 3, 4, 5];
          // TODO port over the hamcrest matcher that checks if the given item is in the an array.
          assertThat(values.indexOf(random(values)), not(equalTo(-1)));
        });
      });
      
      describe('reject', function():void {
        it('filters an Array for items that dont match the iterator', function():void {
          var obj:Object = { n: 4 };
          var others:Array = reject([1, 2, 3, true, obj], asx.object.isA(Number));
          assertThat(others, equalTo([true, obj]));
        });
      });
      
      describe('difference', function():void {
        it('returns the items that were not in both input arrays', function():void {
          var one:Array = [1, 2, 3, 4, 5];
          var two:Array = [1, 3, 5, 7, 9];
          assertThat(difference(one, two), equalTo([2, 4, 7, 9]));
        });
      });
      
      describe('intersection', function():void {
        it('returns the items that were in both input arrays', function():void {
          var one:Array = [1, 2, 3, 4, 5];
          var two:Array = [1, 3, 5, 7, 9];
          assertThat(intersection(one, two), equalTo([1, 3, 5]));
        });
      });
      
      describe('union', function():void {
        it('returns the unique items from both arrays', function():void {
          var one:Array = [1, 2, 3, 4, 5];
          var two:Array = [1, 3, 5, 7, 9];
          assertThat(union(one, two), equalTo([1, 2, 3, 4, 5, 7, 9]));
        });
      });
      
      describe('eachSlice', function():void {
        it('groups items into slices of a given size', function():void {
          var array:Array = [1, 2, 3, 4, 5, 6, 7];
          var slices:Array = [];
          assertThat(eachSlice(array, 3, I), equalTo([[1, 2, 3], [4, 5, 6], [7]]));
        });
      });
      
      describe('shuffle', function():void {
        it('randomises the order of items in the array', function():void {
          var array:Array = [1, 2, 3, 4, 5];
          var shuffled:Array = shuffle(array);
          assertThat(shuffled, arrayWithSize(5));
          assertThat(shuffled, hasItems(1, 2, 3, 4, 5));
        });
      });
      
      describe('empty', function():void {
        it('returns true for null', function():void {
          assertThat(empty(null), equalTo(true));
        });
        it('returns true for array with no items', function():void {
          assertThat(empty([]), equalTo(true));
        });
        it('returns false for array with null items', function():void {
          assertThat(empty([null]), equalTo(false));
          assertThat(empty([null, null]), equalTo(false));
        });
        it('returns false for array with items', function():void {
          assertThat(empty([0]), equalTo(false));
          assertThat(empty([0, 1, 2]), equalTo(false));
        });
      });
    });
  }
}
