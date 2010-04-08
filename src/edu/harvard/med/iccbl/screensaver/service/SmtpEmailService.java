// $HeadURL:
// svn+ssh://js163@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/.eclipse.prefs/codetemplates.xml
// $
// $Id$
//
// Copyright © 2006, 2010 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.iccbl.screensaver.service;

import java.util.Arrays;
import java.util.Properties;

import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

import org.apache.commons.cli.OptionBuilder;
import org.apache.commons.cli.ParseException;
import org.apache.log4j.Logger;

import edu.harvard.med.screensaver.CommandLineApplication;
import edu.harvard.med.screensaver.service.EmailService;

public class SmtpEmailService implements EmailService
{
  private static Logger log = Logger.getLogger(SmtpEmailService.class);
  
  public static final int SHORT_OPTION_INDEX = 0;
  public static final int LONG_OPTION_INDEX = 1;
  public static final int DESCRIPTION_INDEX = 2;
  public static final String[] MAIL_FROM_OPTION = { "mf", "mail-from", "from address for the mail, defaults to the username" };
  public static final String[] MAIL_CC_LIST_OPTION = 
  { "cclist", "mail-cc-list", "the cc recipient(s) of the message, delimited by \"" + DELIMITER + "\"" };
  public static final String[] MAIL_RECIPIENT_LIST_OPTION = 
  { "recipientlist", "mail-recipient-list", "the recipient(s) of the message, delimited by \"" + DELIMITER + "\"" };
  public static final String[] MAIL_MESSAGE_OPTION = { "mm", "mail-message", "the mail message" };
  public static final String[] MAIL_SUBJECT_OPTION = { "ms", "mail-subject", "the mail subject" };
  public static final String[] MAIL_SERVER_OPTION = { "mh", "mail-host", "the smtp mail server host" };
  public static final String[] MAIL_USERNAME_OPTION = { "mu", "mail-user", "the smtp mail user" };
  public static final String[] MAIL_USER_PASSWORD_OPTION = { "mp", "mail-password", "the smtp mail user password" };
  public static final String[] MAIL_USE_SMTPS = { "smtps", "use-smtps", "use SMTPS Auth (gmail)" };

  // member variables used if instantiated as a service
  private String host;
  private String username;
  private String password;
  private boolean useSmtps;

  public SmtpEmailService(String host, String username)
  {
    this(host,username, null,false);
  }  
  
  /**
   * @motivation for Spring instantiation
   * @param host mail server host i.e. smtp.cl.med.harvard.edu
   * @param username mail account name
   * @param password password, can be blank if unnecessary
   * @param useSmtps in order to use smtp.gmail.com (for testing)
   */
  public SmtpEmailService(String host, String username, String password)
  {
    this(host,username, password,false);
  }

  /**
   * @param useSmtps in order to use smtp.gmail.com (for testing)
   */
  public SmtpEmailService(String host, String username, String password, boolean useSmtps)
  {
    this.host = host;
    this.username = username;
    this.password = password;
    this.useSmtps = useSmtps;
  }

  /**
   * For logging
   */
  public static String printEmail(String subject,
                                  String message,
                                  InternetAddress from,
                                  InternetAddress[] recipients,
                                  InternetAddress[] cclist)
  {
    return printEmailHeader(subject, from, recipients, cclist)  
             + "\n========message========\n" + message;
  }
 
  public static String printEmailHeader(String subject,
                                  InternetAddress from,
                                  InternetAddress[] recipients,
                                  InternetAddress[] cclist)
  {
    return "\nSubject: " + subject 
             + "\nFrom: " + from 
             + "\nTo: " + com.google.common.base.Joiner.on(',').join(recipients) 
             + "\nCC: " + (cclist == null ? "" : com.google.common.base.Joiner.on(',').join(cclist));
  }
                                  
  public void send(String subject,
                   String message,
                   String from,
                   String[] recipients,
                   String[] cclist) throws MessagingException
  {
    send(subject, message, from, recipients, cclist, host, username, password, useSmtps);
  }   
  
  public void send(String subject,
                       String message,
                       InternetAddress from,
                       InternetAddress[] recipients,
                       InternetAddress[] cclist) throws MessagingException
  {
    send(subject, message, from, recipients, cclist, host, username, password, useSmtps);
  } 
  
  private static void send(
                     String subject,
                     String message,
                     String from,
                     String[] srecipients,
                     String[] scclist,
                     String host,
                     String username, 
                     String password, 
                     boolean useSmtps) 
    throws MessagingException
  {
    InternetAddress[] recipients = new InternetAddress[srecipients.length];
    int i = 0;
    for(String r:srecipients)
    {
      recipients[i++] = new InternetAddress(r);

    }      
    InternetAddress[] cclist = null;
    i = 0;
    if(scclist != null)
    {
      cclist = new InternetAddress[scclist.length];
      for(String r:scclist)
      {
        cclist[i++]= new InternetAddress(r);
      }
    }
    send(subject, message, new InternetAddress(from), recipients, cclist, host, username, password, useSmtps);
  }
  
  private static void send(
                     String subject,
                     String message,
                     InternetAddress from,
                     InternetAddress[] recipients,
                     InternetAddress[] cclist,
                     String host,
                     String username, 
                     String password, 
                     boolean useSmtps) 
    throws MessagingException
  {
    log.info("try to send: " + printEmail(subject, message, from, recipients, cclist));
    log.info("host: " + host + ", useSMTPS: " + useSmtps);
    Properties props = new Properties();
    String protocol = "smtp";
    if(useSmtps)  // need smtps to test with gmail
    {
      props.put("mail.smtps.auth", "true");
      protocol = "smtps";
    }
    Session session = Session.getDefaultInstance(props, null);
    Transport t = session.getTransport(protocol);

    try {
      MimeMessage msg = new MimeMessage(session);
      msg.setFrom(from);  
      msg.setSubject(subject);
      msg.setContent(message, "text/plain");
      msg.addRecipients(Message.RecipientType.TO, recipients );
      msg.addRecipients(Message.RecipientType.CC, cclist);
      t.connect(host, username, password);
      t.sendMessage(msg, msg.getAllRecipients());
    }
    finally {
      t.close();
    }
    log.info("sent: " + printEmailHeader(subject, from, recipients, cclist) );
  }

  @SuppressWarnings("static-access")
  public static void main(String[] args) throws Exception
  {

    CommandLineApplication app = new CommandLineApplication(args);
    app.addCommandLineOption(OptionBuilder.hasArg()
                             .withArgName(MAIL_RECIPIENT_LIST_OPTION[SHORT_OPTION_INDEX])
                             .isRequired()
                             .withDescription(MAIL_RECIPIENT_LIST_OPTION[DESCRIPTION_INDEX])
                             .withLongOpt(MAIL_RECIPIENT_LIST_OPTION[LONG_OPTION_INDEX])
                             .create(MAIL_RECIPIENT_LIST_OPTION[SHORT_OPTION_INDEX]));
    app.addCommandLineOption(OptionBuilder.hasArg()
                             .withArgName(MAIL_CC_LIST_OPTION[SHORT_OPTION_INDEX])
                             .isRequired()
                             .withDescription(MAIL_CC_LIST_OPTION[DESCRIPTION_INDEX])
                             .withLongOpt(MAIL_CC_LIST_OPTION[LONG_OPTION_INDEX])
                             .create(MAIL_CC_LIST_OPTION[SHORT_OPTION_INDEX]));
    app.addCommandLineOption(OptionBuilder.hasArg()
                             .withArgName(MAIL_MESSAGE_OPTION[SHORT_OPTION_INDEX])
                             .isRequired()
                             .withDescription(MAIL_MESSAGE_OPTION[DESCRIPTION_INDEX])
                             .withLongOpt(MAIL_MESSAGE_OPTION[LONG_OPTION_INDEX])
                             .create(MAIL_MESSAGE_OPTION[SHORT_OPTION_INDEX]));
    app.addCommandLineOption(OptionBuilder.hasArg()
                             .withArgName(MAIL_SUBJECT_OPTION[SHORT_OPTION_INDEX])
                             .isRequired()
                             .withDescription(MAIL_SUBJECT_OPTION[DESCRIPTION_INDEX])
                             .withLongOpt(MAIL_SUBJECT_OPTION[LONG_OPTION_INDEX])
                             .create(MAIL_SUBJECT_OPTION[SHORT_OPTION_INDEX]));
    app.addCommandLineOption(OptionBuilder.hasArg()
                             .withArgName(MAIL_SERVER_OPTION[SHORT_OPTION_INDEX])
                             .isRequired()
                             .withDescription(MAIL_SERVER_OPTION[DESCRIPTION_INDEX])
                             .withLongOpt(MAIL_SERVER_OPTION[LONG_OPTION_INDEX])
                             .create(MAIL_SERVER_OPTION[SHORT_OPTION_INDEX]));
    app.addCommandLineOption(OptionBuilder.hasArg()
                             .withArgName(MAIL_USERNAME_OPTION[SHORT_OPTION_INDEX])
                             .isRequired()
                             .withDescription(MAIL_USERNAME_OPTION[DESCRIPTION_INDEX])
                             .withLongOpt(MAIL_USERNAME_OPTION[LONG_OPTION_INDEX])
                             .create(MAIL_USERNAME_OPTION[SHORT_OPTION_INDEX]));
    app.addCommandLineOption(OptionBuilder.hasArg()
                             .withArgName(MAIL_USER_PASSWORD_OPTION[SHORT_OPTION_INDEX])
                             .isRequired()
                             .withDescription(MAIL_USER_PASSWORD_OPTION[DESCRIPTION_INDEX])
                             .withLongOpt(MAIL_USER_PASSWORD_OPTION[LONG_OPTION_INDEX])
                             .create(MAIL_USER_PASSWORD_OPTION[SHORT_OPTION_INDEX]));
    app.addCommandLineOption(OptionBuilder.hasArg()
                             .withArgName(MAIL_FROM_OPTION[SHORT_OPTION_INDEX])
                             .withDescription(MAIL_FROM_OPTION[DESCRIPTION_INDEX])
                             .withLongOpt(MAIL_FROM_OPTION[LONG_OPTION_INDEX])
                             .create(MAIL_FROM_OPTION[SHORT_OPTION_INDEX]));
    app.addCommandLineOption(OptionBuilder.hasArg(false)
                             .withDescription(MAIL_USE_SMTPS[DESCRIPTION_INDEX])
                             .withLongOpt(MAIL_USE_SMTPS[LONG_OPTION_INDEX])
                             .create(MAIL_USE_SMTPS[SHORT_OPTION_INDEX]));


    try {
      if (!app.processOptions(/* acceptDatabaseOptions= */true,
      /* showHelpOnError= */true)) {
        return;
      }

      String message = app.getCommandLineOptionValue(MAIL_MESSAGE_OPTION[SHORT_OPTION_INDEX]);
      String subject = app.getCommandLineOptionValue(MAIL_SUBJECT_OPTION[SHORT_OPTION_INDEX]);
      String recipientlist = app.getCommandLineOptionValue(MAIL_RECIPIENT_LIST_OPTION[SHORT_OPTION_INDEX]);
      String[] recipients = recipientlist.split(DELIMITER);
      
      String cclist = app.getCommandLineOptionValue(MAIL_CC_LIST_OPTION[SHORT_OPTION_INDEX]);
      String[] ccrecipients = cclist.split(DELIMITER);
      
      String mailHost = app.getCommandLineOptionValue(MAIL_SERVER_OPTION[SHORT_OPTION_INDEX]);
      String username = app.getCommandLineOptionValue(MAIL_USERNAME_OPTION[SHORT_OPTION_INDEX]);
      String password = app.getCommandLineOptionValue(MAIL_USER_PASSWORD_OPTION[SHORT_OPTION_INDEX]);
      boolean useSmtps = app.isCommandLineFlagSet(MAIL_USE_SMTPS[SHORT_OPTION_INDEX]);

      String mailFrom = username;
      if(app.isCommandLineFlagSet(MAIL_FROM_OPTION[SHORT_OPTION_INDEX])){
        mailFrom = app.getCommandLineOptionValue(MAIL_FROM_OPTION[SHORT_OPTION_INDEX]);
      }
      
      //TODO: get the cclist

      send(subject, message, mailFrom, recipients, ccrecipients, mailHost, username, password, useSmtps);
      System.exit(0);
    }
    catch (ParseException e) {
      log.error("error parsing command line options: " + e.getMessage());
    }
    System.exit(1); // error

  }

//  private void send2(String mailHost,
//                        String username,
//                        String password)
//    throws NoSuchProviderException,
//    MessagingException,
//    AddressException
//  {
//    Properties props = new Properties();
//    props.setProperty("mail.transport.protocol", "smtp");
//    props.setProperty("mail.host", mailHost);
//    props.setProperty("mail.user", username);
//    props.setProperty("mail.password", password);
//
//
//    Session mailSession = Session.getDefaultInstance(props, null);
//    Transport transport = mailSession.getTransport();
//
//    MimeMessage message = new MimeMessage(mailSession);
//    message.setSubject("Testing javamail plain");
//    message.setContent("This is a test", "text/plain");
//    message.addRecipient(Message.RecipientType.TO,
//                         new InternetAddress("sean.erickson@gmail.com"));
//
//    transport.connect();
//    transport.sendMessage(message,
//                          message.getRecipients(Message.RecipientType.TO));
//    transport.close();
//  }
}