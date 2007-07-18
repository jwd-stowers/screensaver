// $HeadURL: svn+ssh://js163@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/.eclipse.prefs/codetemplates.xml $
// $Id: codetemplates.xml 169 2006-06-14 21:57:49Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.util.eutils;

import java.util.List;

import edu.harvard.med.screensaver.AbstractSpringTest;

/**
 * Test the {@link PubchemCidListProvider}.
 * <p>
 * WARNING: this test requires an internet connection.
 *
 * @author <a mailto="john_sullivan@hms.harvard.edu">John Sullivan</a>
 * @author <a mailto="andrew_tolopko@hms.harvard.edu">Andrew Tolopko</a>
 */
public class PubchemSmilesSearchTest extends AbstractSpringTest
{
  private PubchemSmilesSearch _pubchemSmilesSearch = new PubchemSmilesSearch();

  public void testGetPubchemCidsForSmiles1()
  {
    List<String> pubchemCids = _pubchemSmilesSearch.getPubchemCidsForSmiles(
      "Clc1ccc(\\C=C/c2c(C)n(C)n(c3ccccc3)c2=O)c(Cl)c1");
    assertEquals(0, pubchemCids.size());
  }

  public void testGetPubchemCidsForSmiles2()
  {
    List<String> pubchemCids = _pubchemSmilesSearch.getPubchemCidsForSmiles(
      "N#Cc1c(CN2CCN(C)CC2)n(C)c2ccccc12");
    assertEquals(1, pubchemCids.size());
    assertEquals("607443", pubchemCids.get(0));
  }

  public void testGetPubchemCidsForSmiles3()
  {
    List<String> pubchemCids = _pubchemSmilesSearch.getPubchemCidsForSmiles(
      "NC(=S)c1cnc2ccccn2c1=N");
    assertEquals(1, pubchemCids.size());
    assertEquals("687414", pubchemCids.get(0));
  }
}
