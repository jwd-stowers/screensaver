// $HeadURL: svn+ssh://js163@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/.eclipse.prefs/codetemplates.xml $
// $Id: codetemplates.xml 169 2006-06-14 21:57:49Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.io.libraries;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.StringReader;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import edu.harvard.med.screensaver.db.DAO;
import edu.harvard.med.screensaver.db.DAOTransaction;
import edu.harvard.med.screensaver.model.libraries.Well;
import edu.harvard.med.screensaver.model.libraries.WellKey;
import edu.harvard.med.screensaver.util.StringUtils;

import org.apache.log4j.Logger;

public class PlateWellListParser
{
  // static members

  private static Logger log = Logger.getLogger(PlateWellListParser.class);

  
  // TODO: consider moving these to WellKey
  private static final Pattern _plateWellHeaderLinePattern = Pattern.compile(
    "^\\s*plate\\s+well\\s*$",
    Pattern.CASE_INSENSITIVE);
  private static final Pattern _plateWellPattern = Pattern.compile(
    "^\\s*((PL[-_]?)?(\\d+))[A-P](0?[1-9]|1[0-9]|2[0-4]).*",
    Pattern.CASE_INSENSITIVE);
  private static final Pattern _plateNumberPattern = Pattern.compile(
    "^\\s*(PL[-_]?)?(\\d+)\\s*$",
    Pattern.CASE_INSENSITIVE);
  private static final Pattern _wellNamePattern = Pattern.compile(
    "^\\s*([A-P](0?[1-9]|1[0-9]|2[0-4]))\\s*$",
    Pattern.CASE_INSENSITIVE);


  // instance data members
  
  private DAO _dao;

  // public constructors and methods
  
  public PlateWellListParser(DAO dao)
  {  
    _dao = dao;
  }

  /**
   * Parse and return the list of wells from the plate-well list.
   * Helper method for {@link #findWells(String)}.
   * @param plateWellList the plate-well list
   * @throws IOException
   * @return the list of wells
   */
  public PlateWellListParserResult lookupWellsFromPlateWellList(final String plateWellList) 
  {
    final PlateWellListParserResult result = new PlateWellListParserResult();
    _dao.doInTransaction(new DAOTransaction()
    {
      public void runTransaction()
      {
        BufferedReader plateWellListReader = new BufferedReader(new StringReader(plateWellList));
        try {
          int lineNumber = 0;
          for (
            String line = plateWellListReader.readLine();
            line != null;
            line = plateWellListReader.readLine()) {

            ++lineNumber;
            
            // skip lines that say "Plate Well"
            Matcher matcher = _plateWellHeaderLinePattern.matcher(line);
            if (matcher.matches()) {
              continue;
            }

            // separate initial plate and well with a space if necessary
            line = splitInitialPlateWell(line);

            // split the line into tokens; should be one plate, then one or more wells
            String [] tokens = line.split("[\\s;,]+");
            if (tokens.length == 0) {
              continue;
            }

            Integer plateNumber = parsePlateNumber(tokens[0]);
            if (plateNumber == null) {
              result.addSyntaxError(lineNumber, "invalid plate number " + tokens[0]);
              continue;
            }
            for (int i = 1; i < tokens.length; i ++) {
              String wellName = parseWellName(tokens[i]);
              if (wellName == null) {
                result.addSyntaxError(lineNumber, "invalid well name " + tokens[i]);
                continue;
              }
              Well well = lookupWell(plateNumber, wellName);
              if (well == null) {
                result.addWellNotFound(new WellKey(plateNumber, wellName));
                continue;
              }
              else {
                result.addWell(well);
              }
            }
          }
        }
        catch (IOException e) {
          result.addSyntaxError(0, "internal error");
        }
      }
    });
    return result;
  }
  
  /**
   * Parse and return the well for the plate number and well name.
   * Helper method for {@link #findWell(Integer, String)}.
   * @param plateNumberString the unparsed plate number
   * @param wellName the unparsed well name
   * @return the well
   */
  public Well lookupWell(String plateNumberString, String wellName)
  {
    Integer plateNumber = parsePlateNumber(plateNumberString);
    wellName = parseWellName(wellName);
    if (plateNumber == null || wellName == null) {
      return null;
    }
    return lookupWell(plateNumber, wellName);
  }

  
  // private methods

  /**
   * Lookup the well from the dao by plate number and well name.
   * @param plateNumber the parsed plate number
   * @param wellName the parse well name
   * @return
   */
  private Well lookupWell(final Integer plateNumber, final String wellName) 
  {
    WellKey wellKey = new WellKey(plateNumber, wellName);
    Well well = _dao.findWell(wellKey); 
    if (well != null) {
      // force initialization of persistent collections needed by search result viewer
      well.getGenes().size();
      well.getCompounds().size();
    }
    return well;
  }
  
  /**
   * Insert a space between the first plate number and well name if there is no
   * space there already.
   * @param line the line to patch up
   * @return the patched up line
   */
  private String splitInitialPlateWell(String line)
  {
    Matcher matcher = _plateWellPattern.matcher(line);
    if (matcher.matches()) {
      int spliceIndex = matcher.group(1).length();
      line = line.substring(0, spliceIndex) + " " + line.substring(spliceIndex);
    }
    return line;
  }
  
  /**
   * Parse the plate number.
   */
  private Integer parsePlateNumber(String plateNumber)
  {
    Matcher matcher = _plateNumberPattern.matcher(plateNumber);
    if (matcher.matches()) {
      plateNumber = matcher.group(2);
      try {
        return Integer.parseInt(plateNumber);
      }
      catch (NumberFormatException e) {
        // this seems unlikely given the _plateNumberPattern match, but it's actually possible
        // to match that pattern and still get a NFE, if the number is larger than MAXINT
      }
    }
    return null;
  }
  
  /**
   * Parse the well name.
   */
  private String parseWellName(String wellName)
  {
    Matcher matcher = _wellNamePattern.matcher(wellName);
    if (matcher.matches()) {
      wellName = matcher.group(1);
      if (wellName.length() == 2) {
        wellName = wellName.charAt(0) + "0" + wellName.charAt(1);
      }
      wellName = StringUtils.capitalize(wellName);
      return wellName;
    }
    return null;
  }
}
