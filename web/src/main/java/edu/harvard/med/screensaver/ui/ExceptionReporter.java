// $HeadURL$
// $Id$

// Copyright © 2006, 2010, 2011, 2012 by the President and Fellows of Harvard College.

// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.ui;

import java.util.ArrayList;
import java.util.List;

import javax.faces.model.DataModel;
import javax.faces.model.ListDataModel;
import javax.servlet.ServletException;

import edu.harvard.med.screensaver.ui.arch.view.AbstractBackingBean;
import edu.harvard.med.screensaver.util.Pair;

/**
 * Backing bean for view that displays error message, when an unexpected error
 * occurs, and provides some continuation options for users. For developers,
 * shows formatted stack traces for exception chain.
 *
 * @author <a mailto="andrew_tolopko@hms.harvard.edu">Andrew Tolopko</a>
 * @author <a mailto="john_sullivan@hms.harvard.edu">John Sullivan</a>
 */
public class ExceptionReporter extends AbstractBackingBean
{
  public static final String EXCEPTION_SESSION_PARAM = "javax.servlet.error.exception";

  private Menu _menu;

  public void setMenu(Menu menuController)
  {
    _menu = menuController;
  }

  public String loginAgain()
  {
    return _menu.logout();
  }

  public DataModel getThrowablesDataModel()
  {
    return new ListDataModel(getStackTrace());
  }

  private List<ExceptionInfo> getStackTrace()
  {
    List<ExceptionInfo> throwables = new ArrayList<ExceptionInfo>();
    Throwable t = (Throwable) getHttpSession().getAttribute(EXCEPTION_SESSION_PARAM);
    while (t != null) {
      throwables.add(new ExceptionInfo(t));
      if (t instanceof ServletException) {
        t = ((ServletException) t).getRootCause();
      }
      else {
        t = t.getCause();
      }
    }
    return throwables;
  }

  public static class ExceptionInfo
  {
    private String nameAndMessage;
    private DataModel stackTrace;

    public ExceptionInfo(Throwable t)
    {
      nameAndMessage = t.getClass().getName() + ": " + t.getMessage();
      List<Pair<Boolean,String>> lines = new ArrayList<Pair<Boolean,String>>();
      for (StackTraceElement e : t.getStackTrace()) {
        lines.add(new Pair<Boolean,String>(e.getClassName().indexOf("edu.harvard") != -1,
                                           e.toString()));
      }
      stackTrace = new ListDataModel(lines);
    }

    public String getNameAndMessage()
    {
      return nameAndMessage;
    }

    public DataModel getStackTraceDataModel()
    {
      return stackTrace;
    }
  }
}
