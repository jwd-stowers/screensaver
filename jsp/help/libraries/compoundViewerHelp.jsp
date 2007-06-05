<%@ taglib uri="http://java.sun.com/jsf/html"        prefix="h"     %>
<%@ taglib uri="http://java.sun.com/jsf/core"        prefix="f"     %>
<%@ taglib uri="http://myfaces.apache.org/tomahawk"  prefix="t"     %>
<%@ taglib uri="http://struts.apache.org/tags-tiles" prefix="tiles" %>

<f:subview id="compoundViewerHelpText">
  <f:verbatim escape="false">
    <p>
      The Compound Viewer page displays basic information about a compound, as well as 2D
      structure image, and a list of the library wells where the compound can be found.
    </p>
    <p>
      When "Is Salt" has the value "true", this generally indicates that the compound is
      not potentially bioactive, but is present in solution with other potentially bioactive
      compounds.
    </p>
    <p>
      <b><i>Please note</i></b> we are currently working on getting PubChem IDs for all of
      our compounds. Currently, about 40% of our compounds have PubChem IDs. Thank you for
      your patience!
    </p>
    <p>
      <b><i>Internet Explorer Tip:</i></b> Are you getting a "Security Information" popup
      window every time you try to view a well with compounds in it? Here's a workaround:
      <ol>
        <li>Open the Tools menu</li>
        <li>Click on Internet Options...</li>
        <li>Click on Security</li>
        <li>Click on Custom Level...</li>
        <li>Scroll down to "Display mixed content"</li>
        <li>Select "Enable"</li>
        <li>Click OK</li>
        <li>Click Yes</li>
        <li>Click OK</li>
      </ol>
      A better solution may be to <a href="http://www.mozilla.com/">download Firefox</a>.
    </p>
  </f:verbatim>
</f:subview>