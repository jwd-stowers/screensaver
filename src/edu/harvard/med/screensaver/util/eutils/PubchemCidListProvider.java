// $HeadURL: svn+ssh://js163@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/.eclipse.prefs/codetemplates.xml $
// $Id: codetemplates.xml 169 2006-06-14 21:57:49Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.util.eutils;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.apache.log4j.Logger;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * Queries PubChem to provide a list of PubChem CIDs for a given SMILES string.
 *
 * @author <a mailto="john_sullivan@hms.harvard.edu">John Sullivan</a>
 * @author <a mailto="andrew_tolopko@hms.harvard.edu">Andrew Tolopko</a>
 */
public class PubchemCidListProvider
{
  // static fields

  private static final Logger log = Logger.getLogger(PubchemCidListProvider.class);
  private static final String EUTILS_ROOT = "http://www.ncbi.nlm.nih.gov/entrez/eutils";
  private static final String ESEARCH_URL = EUTILS_ROOT + "/esearch.fcgi";
  private static final int NUM_RETRIES = 5;
  private static final int CONNECT_TIMEOUT = 5000; // in millisecs
  
  
  // public instance fields
  
  private DocumentBuilder _documentBuilder;
  private class PubChemConnectionException extends Exception {
    private static final long serialVersionUID = 1L;
  };
  
  
  // public constructor and instance method
  
  public PubchemCidListProvider()
  {
    DocumentBuilderFactory documentBuilderFactory = DocumentBuilderFactory.newInstance();
    try {
      _documentBuilder = documentBuilderFactory.newDocumentBuilder();
    }
    catch (ParserConfigurationException e) {
      log.error("unable to initialize the XML document builder", e);
    }
  }

  public List<String> getPubchemCidListForInchi(String inchi)
  {
    for (int i = 0; i < NUM_RETRIES; i ++) {
      try {
        return getPubChemCidListForInchi0(inchi);        
      }
      catch (PubChemConnectionException e) {
      }
    }
    log.error("couldnt get PubChem CIDs for InChI after " + NUM_RETRIES + " tries.");
    return new ArrayList<String>();
  }

  
  // private instance methods

  private List<String> getPubChemCidListForInchi0(String inchi)
  throws PubChemConnectionException {
    List<String> pubchemCids = new ArrayList<String>();
    InputStream esearchContent = getEsearchContent(inchi);
    if (esearchContent == null) {
      return pubchemCids;
    }
    
    Document efetchDocument = getDocumentFromInputStream(esearchContent);
    NodeList efetchIds = efetchDocument.getElementsByTagName("Id");
    for (int i = 0; i < efetchIds.getLength(); i ++) {
      String efetchId = getTextContent(efetchIds.item(i));
      pubchemCids.add(efetchId);
    }
    return pubchemCids;
  }

  private InputStream getEsearchContent(String inchi)
  throws PubChemConnectionException
  {
    try {
      URL url = new URL(
        ESEARCH_URL + "?db=pccompound&usehistory=n&tool=screensaver" +
        "&rettype=uilist&mode=xml" +
        "&email=" +
        URLEncoder.encode("{john_sullivan,andrew_tolopko}@hms.harvard.edu", "UTF-8") +
        "&term=\"" +
        URLEncoder.encode(inchi, "UTF-8") +
        "\"[inchi]"
        );
      HttpURLConnection connection = (HttpURLConnection) url.openConnection();
      connection.setConnectTimeout(CONNECT_TIMEOUT);
      connection.setReadTimeout(CONNECT_TIMEOUT);
      connection.connect();
      return connection.getInputStream();
    }
    catch (Exception e) {
      log.warn(
        "couldnt get eSearch content from NCBI for inchi " + inchi + ": " +
        e.getMessage());
      throw new PubChemConnectionException();
    }
  }

  private Document getDocumentFromInputStream(InputStream epostContent)
  throws PubChemConnectionException
  {
    try {
      return _documentBuilder.parse(epostContent);
    }
    catch (Exception e) {
      log.warn("unable to get content from NCBI: " + e.getMessage());
      throw new PubChemConnectionException();
    }
  }

  /**
   * Recursively traverse the nodal structure of the node, accumulating the accumulate
   * parts of the text content of the node and all its children.
   * @param node the node to traversalate
   * @return the accumulative recursive text content of the traversalated node
   */
  private String getTextContent(Node node)
  {
    if (node.getNodeType() == Node.TEXT_NODE) {
      return node.getNodeValue();
    }
    String textContent = "";
    for (Node child = node.getFirstChild(); child != null; child = child.getNextSibling()) {
      textContent += getTextContent(child);
    }
    return textContent;
  }
}
