<%@ taglib uri="http://java.sun.com/jsf/html" prefix="h"%>
<%@ taglib uri="http://java.sun.com/jsf/core" prefix="f"%>
<%@ taglib uri="http://myfaces.apache.org/tomahawk" prefix="t"%>
<%@ taglib uri="http://struts.apache.org/tags-tiles" prefix="tiles"%>

<f:subview id="screensBrowser">
	<h:form id="screensBrowserForm">
		<t:aliasBean alias="#{searchResults}" value="#{screensBrowser}">
			<%@include file="../searchResults.jspf"%>
		</t:aliasBean>
	</h:form>

	<t:panelGroup rendered="#{screensBrowser.entityView}">
		<%@ include file="screenViewer.jsp"%>
	</t:panelGroup>
</f:subview>


