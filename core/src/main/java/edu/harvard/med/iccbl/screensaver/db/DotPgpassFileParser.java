// $HeadURL$
// $Id$
//
// Copyright © 2006, 2010, 2011, 2012 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.iccbl.screensaver.db;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.log4j.Logger;

/**
 * Parses the correct database password from the users .pgpass file.
 *
 * @author <a mailto="john_sullivan@hms.harvard.edu">John Sullivan</a>
 * @author <a mailto="andrew_tolopko@hms.harvard.edu">Andrew Tolopko</a>
 */
public class DotPgpassFileParser
{
  private static Logger log = Logger.getLogger(DotPgpassFileParser.class);

  synchronized public String getPasswordFromDotPgpassFile(String hostname,
                                                          String port,
                                                          String database,
                                                          String user) throws IOException
  {
    File pgpassFile = new File(System.getProperty("user.home"), ".pgpass");
    Pattern pattern = Pattern.compile("(\\S+?):(\\S+?):(\\S+?):(\\S+?):(\\S*)");
    FileInputStream pgpassInputStream = new FileInputStream(pgpassFile);
    InputStreamReader pgpassInputStreamReader = new InputStreamReader(pgpassInputStream);
    BufferedReader pgpassBufferedReader = new BufferedReader(pgpassInputStreamReader);
    String line = pgpassBufferedReader.readLine();
    while (line != null) {
      Matcher matcher = pattern.matcher(line);
      if (matcher.matches()) {
        String hostnameMatch = matcher.group(1);
        String portMatch = matcher.group(2);
        String databaseMatch = matcher.group(3);
        String userMatch = matcher.group(4);
        String passwordMatch = matcher.group(5);

        if ((hostnameMatch.equals("*") || hostnameMatch.equals(hostname)) &&
          (portMatch.equals("*") || portMatch.equals(port)) &&
          (databaseMatch.equals("*") || databaseMatch.equals(database)) &&
          (userMatch.equals("*") || userMatch.equals(user))) {
          return passwordMatch;
        }
      }
      line = pgpassBufferedReader.readLine();
    }
    log.error("unable to find a matching entry in .pgpass file for user " + user);
    return null;
  }
}

