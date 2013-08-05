package xtend

import java.util.regex.Pattern

class RegExExtensions {
	
	def static readRegEx(String content, String regEx) {
		val pattern = Pattern::compile(regEx, Pattern::DOTALL)
		val matcher = pattern.matcher(content)
		if(matcher.find) {
			matcher.group(1)
		} else {
			null
		}
	}
}