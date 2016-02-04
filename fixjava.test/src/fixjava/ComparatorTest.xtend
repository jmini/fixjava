package fixjava

import java.util.Comparator
import org.junit.Test
import static org.junit.Assert.*;

class ComparatorTest {
	val Comparator<String> comparator = [s1, s2 | 
		if(s1.startsWith(s2)) {
			return -1
		} else if(s2.startsWith(s1)) {
			return 1
		}
		s1.compareTo(s2)
	]

	@Test
	def test() {
		"aa".testBiggerThan("bb")
		"aaa".testBiggerThan("aa")
		
		val origin = #["bbb", "aaa", "abc"]
		val expected = #["aaa", "abc", "bbb"]
		assertEquals(expected, origin.sortWith(comparator))
	}
	
	def testBiggerThan(String big, String small) {
		assertTrue(comparator.compare(big, small) < 0)
		assertTrue(comparator.compare(small, big) > 0)
	}
}