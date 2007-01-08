// $HeadURL: svn+ssh://js163@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/.eclipse.prefs/codetemplates.xml $
// $Id: codetemplates.xml 169 2006-06-14 21:57:49Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

import org.apache.log4j.Logger;

public class ScreensaverProperties
{
  // static fields

  private static Logger log = Logger.getLogger(ScreensaverProperties.class);
  private static final String SCREENSAVER_PROPERTIES_RESOURCE = 
    "../../../../screensaver.properties"; // relative to current package
  private static Properties _screensaverProperties = new Properties();
  static {
    InputStream screensaverPropertiesInputStream =
      ScreensaverProperties.class.getResourceAsStream(SCREENSAVER_PROPERTIES_RESOURCE);
    try {
      _screensaverProperties.load(screensaverPropertiesInputStream);
    }
    catch (IOException e) {
      log.error("error loading screensaver.properties resource", e);
    }
  }
  
  
  // static methods
  
  public static String getProperty(String name)
  {
    return _screensaverProperties.getProperty(name);
  }
}

