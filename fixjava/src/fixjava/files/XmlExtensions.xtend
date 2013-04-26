package fixjava.files

import java.io.File
import java.io.FileInputStream
import java.util.ArrayList
import java.util.Collections
import javax.xml.parsers.DocumentBuilderFactory
import javax.xml.xpath.XPathConstants
import javax.xml.xpath.XPathFactory
import org.w3c.dom.Document
import org.w3c.dom.Node
import org.w3c.dom.NodeList
import org.xml.sax.InputSource
import java.util.List
import javax.xml.transform.TransformerFactory
import javax.xml.transform.OutputKeys
import javax.xml.transform.dom.DOMSource
import java.io.StringWriter
import javax.xml.transform.stream.StreamResult
import java.io.StringReader
import java.io.FileOutputStream

class XmlExtensions {
	
	val static docFactory = DocumentBuilderFactory::newInstance()=>[it.namespaceAware = true]
	val static xPathfactory = XPathFactory::newInstance();
	val static transformerFactory = TransformerFactory::newInstance() =>[it.setAttribute("indent-number", 4)]
	
	def static toInputSource(File file) {
		return new InputSource(new FileInputStream(file))
	}
	
	def static toInputSource(String content) {
		return new InputSource(new StringReader(content))
	}
	
	def static toDocument(File file) {
		return file.toInputSource.toDocument;
	}
	
	def static toDocument(String content) {
		return content.toInputSource.toDocument;
	}
	
	def static toDocument(InputSource inputSource) {
		val builder = docFactory.newDocumentBuilder();
		val document = builder.parse(inputSource)
		return document
	}
	
	def static toXml(Document document) {
		val StringWriter stringWriter = new StringWriter()
		val StreamResult xmlOutput = new StreamResult(stringWriter)
		document.toXml(xmlOutput)
		return xmlOutput.getWriter().toString()
	}
	
	def static toXml(Document document, File file) {
		val xmlOutput = new StreamResult(new FileOutputStream(file))
		document.toXml(xmlOutput)
	}
	
	
	def static toXml(Document document, StreamResult xmlOutput) {
//		val docOutput = docFactory.newDocumentBuilder.newDocument
//		document.children.forEach[
//			val copy = docOutput.adoptNode(it.cloneNode(true))
//			docOutput.appendChild(copy)
//		]
//		docOutput.copyNode(docOutput, document)
		
		document.xmlStandalone = true;
		
		val transformer = transformerFactory.newTransformer()
		transformer.setOutputProperty(OutputKeys::INDENT, "yes")
//		transformer.setOutputProperty(OutputKeys::STANDALONE, "yes")
		transformer.transform(new DOMSource(document), xmlOutput)
	}
	
//	def private static copyNode(Node copyNode, Document copyDocument, Node originalNode) {
//		originalNode.children.forEach[
////			val copyChild = copyDocument.cre
////			copy.appendChild(it)
//			if(it.hasChildNodes) {
//				
//			}
//		]
//	}
	
	
	def static selectByXPathQuery(Document doc, String xpathQuery) {
		val xpath = xPathfactory.newXPath();
		val expr = xpath.compile(xpathQuery);
		val nodes = expr.evaluate(doc, XPathConstants::NODESET) as NodeList
		
		return nodes.asList
	}
	
	def static childNode(Node node, String nodeName) {
		return node.childNodes.asList.filter[it.nodeName == nodeName].ensureAndGetFirst("1 child node <"+nodeName+"> for <"+node.nodeName+">")
	}
	
	def static getOrCreateChildNode(Node node, String nodeName, Document document) {
		if(!node.hasChildNodes) {
			return node.appendChild(document.createElement(nodeName))
		}
		val list = node.childNodes.asList.filter[it.nodeName == nodeName];
		if(list.size == 0) {
			return node.appendChild(document.createElement(nodeName))
		} else if (list.size == 1) {
			return list.get(0)
		} else {
			throw new IllegalStateException("Was expecting 1 child node <"+nodeName+"> for <"+node.nodeName+"> and found " + list.size + " nodes")
		}
	}
	
	def static node(List<Node> nodes) {
		return nodes.ensureAndGetFirst("a list with 1 element")
	}
	
	def private static ensureAndGetFirst(Iterable<Node> nodes, String errorMessage) {
		if(nodes.size == 0) {
			throw new IllegalStateException("Was expecting " + errorMessage + " and found nothing")
		} else if(nodes.size > 1) {
			throw new IllegalStateException("Was expecting " + errorMessage + " and found "+nodes.size + " nodes")
		}
		return nodes.get(0)
	}
	
	def static children(Node node) {
		return node.childNodes.asList
	}
	
	def static asList(NodeList nodeList) {
		var i = 0
		val result = new ArrayList<Node>
		while (i < nodeList.getLength()) {
			result.add(nodeList.item(i))
			i = i+1
		}
		return Collections::unmodifiableList(result);
	}
}