
package edu.mit.broad.chembank.shared.mda.webservices.service;

import javax.xml.ws.WebFault;


/**
 * This class was generated by the JAX-WS RI.
 * JAX-WS RI 2.1.3-b02-
 * Generated source version: 2.1
 * 
 */
@WebFault(name = "findBySubstructureFault1", targetNamespace = "http://edu.mit.broad.chembank.shared.mda.webservices.service")
public class FindBySubstructure2Fault1
    extends Exception
{

    /**
     * Java type that goes as soapenv:Fault detail element.
     * 
     */
    private WebServiceException faultInfo;

    /**
     * 
     * @param faultInfo
     * @param message
     */
    public FindBySubstructure2Fault1(String message, WebServiceException faultInfo) {
        super(message);
        this.faultInfo = faultInfo;
    }

    /**
     * 
     * @param faultInfo
     * @param message
     * @param cause
     */
    public FindBySubstructure2Fault1(String message, WebServiceException faultInfo, Throwable cause) {
        super(message, cause);
        this.faultInfo = faultInfo;
    }

    /**
     * 
     * @return
     *     returns fault bean: edu.mit.broad.chembank.shared.mda.webservices.service.WebServiceException
     */
    public WebServiceException getFaultInfo() {
        return faultInfo;
    }

}
