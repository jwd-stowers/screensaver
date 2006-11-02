// $HeadURL$
// $Id$
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.db;

import java.io.Serializable;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.springframework.orm.hibernate3.support.HibernateDaoSupport;

import edu.harvard.med.screensaver.model.AbstractEntity;
import edu.harvard.med.screensaver.model.libraries.Gene;
import edu.harvard.med.screensaver.model.libraries.Library;
import edu.harvard.med.screensaver.model.libraries.SilencingReagent;
import edu.harvard.med.screensaver.model.libraries.SilencingReagentType;
import edu.harvard.med.screensaver.model.libraries.Well;
import edu.harvard.med.screensaver.model.screenresults.ScreenResult;
import edu.harvard.med.screensaver.model.users.ScreeningRoomUser;


/**
 * A Spring+Hibernate implementation of the Data Access Object. This is the
 * de-facto DAO implementation for the time being.
 * 
 * @author <a mailto="john_sullivan@hms.harvard.edu">John Sullivan</a>
 * @author <a mailto="andrew_tolopko@hms.harvard.edu">Andrew Tolopko</a>
 */
public class DAOImpl extends HibernateDaoSupport implements DAO
{

  // private static fields
  
  private static final Logger _logger = Logger.getLogger(DAOImpl.class);
  
  
  // public instance methods

  public void doInTransaction(DAOTransaction daoTransaction)
  {
    daoTransaction.runTransaction();
    // TODO: we should be handling exception handling and rollback in an explicit manner
  }
  
  public <E extends AbstractEntity> E defineEntity(
    Class<E> entityClass,
    Object... constructorArguments)
  {
    Constructor<E> constructor = getConstructor(entityClass, constructorArguments);
    E entity = newInstance(constructor, constructorArguments);
    getHibernateTemplate().save(entity);
    return entity;
  }

  public void persistEntity(AbstractEntity entity)
  {
    getHibernateTemplate().saveOrUpdate(entity);
  }
  
  public void deleteEntity(AbstractEntity entity)
  {
    getHibernateTemplate().delete(entity);
  }

  @SuppressWarnings("unchecked")
  public <E extends AbstractEntity> List<E> findAllEntitiesWithType(
    Class<E> entityClass)
  {
    return (List<E>) getHibernateTemplate().loadAll(entityClass);
  }

  @SuppressWarnings("unchecked")
  public <E extends AbstractEntity> E findEntityById(
    Class<E> entityClass,
    Serializable id)
  {
    return (E) getHibernateTemplate().get(entityClass, id);
  }

  @SuppressWarnings("unchecked")
  public <E extends AbstractEntity> List<E> findEntitiesByProperties(
    Class<E> entityClass,
    Map<String,Object> name2Value)
  {
    String entityName = entityClass.getSimpleName();
    StringBuffer hql = new StringBuffer();
    boolean first = true;
    for (String propertyName : name2Value.keySet()) {
      if (first) {
        hql.append("from " + entityName + " x where ");
        first = false;
      }
      else {
        hql.append(" and ");
      }
      hql.append("x.")
         .append(propertyName)
         .append(" = ?");
    }
    return (List<E>) getHibernateTemplate().find(hql.toString(),
                                                 name2Value.values()
                                                           .toArray());
  }
  
  public <E extends AbstractEntity> E findEntityByProperties(
    Class<E> entityClass,
    Map<String,Object> name2Value)
  {
    List<E> entities = findEntitiesByProperties(
      entityClass,
      name2Value);
    if (entities.size() == 0) {
      return null;
    }
    if (entities.size() > 1) {
      throw new IllegalArgumentException(
        "more than one result for DAO.findEntityByProperties");
    }
    return entities.get(0);
  }
  
  @SuppressWarnings("unchecked")
  public <E extends AbstractEntity> List<E> findEntitiesByProperty(
    Class<E> entityClass,
    String propertyName,
    Object propertyValue)
  {
    // note: could delegate this method body to findEntitiesByProperties, but
    // this would require wrapping up property{Name,Value} into a Map object,
    // for no good reason other than (minimal) code sharing
    String entityName = entityClass.getSimpleName();
    String hql = "from " + entityName + " x where x." + propertyName + " = ?";
    return (List<E>) getHibernateTemplate().find(hql, propertyValue);
  }
  
  public <E extends AbstractEntity> E findEntityByProperty(
    Class<E> entityClass,
    String propertyName,
    Object propertyValue)
  {
    List<E> entities = findEntitiesByProperty(
      entityClass,
      propertyName,
      propertyValue);
    if (entities.size() == 0) {
      return null;
    }
    if (entities.size() > 1) {
      throw new IllegalArgumentException(
        "more than one result for DAO.findEntityByProperty");
    }
    return entities.get(0);
  }
  
  @SuppressWarnings("unchecked")
  public <E extends AbstractEntity> List<E> findEntitiesByPropertyPattern(
    Class<E> entityClass,
    String propertyName,
    String propertyPattern)
  {
    String entityName = entityClass.getSimpleName();
    String hql = "from " + entityName + " x where x." + propertyName + " like ?";
    propertyPattern = propertyPattern.replaceAll( "\\*", "%" );
    return (List<E>) getHibernateTemplate().find(hql, propertyPattern);
  }
  
  
  // public special-case data access methods
  
  @SuppressWarnings("unchecked")
  public List<ScreeningRoomUser> findAllLabHeads()
  {
    String hql = "select distinct labHead from ScreeningRoomUser u join u.hbnLabHead labHead";
    return (List<ScreeningRoomUser>) getHibernateTemplate().find(hql);
  }
  
  public void deleteScreenResult(ScreenResult screenResult)
  {
    // disassociate ScreenResult from Screen
    screenResult.getScreen().setScreenResult(null);

    getHibernateTemplate().delete(screenResult);
    _logger.debug("deleted " + screenResult);
  }
  
  public Well findWell(Integer plateNumber, String wellName)
  {
    return findEntityById(Well.class, plateNumber + ":" + wellName);
  }
  
  public SilencingReagent findSilencingReagent(
    Gene gene,
    SilencingReagentType silencingReagentType,
    String sequence)
  {
    return findEntityById(
      SilencingReagent.class,
      gene.toString() + ":" + silencingReagentType.toString() + ":" + sequence);
  }
  
  @SuppressWarnings("unchecked")
  public Library findLibraryWithPlate(Integer plateNumber)
  {
    String hql =
      "select library from Library library where " +
      plateNumber + " between library.startPlate and library.endPlate";
    List<Library> libraries = (List<Library>) getHibernateTemplate().find(hql);
    if (libraries.size() == 0) {
      return null;
    }
    return libraries.get(0); 
  }
  
  
  // private instance methods

  /**
   * Get the constructor for the given Entity class and arguments.
   * @param <E> the entity type
   * @param entityClass the entity class
   * @param arguments the (possibly empty) constructor arguments
   * @return the constructor for the given Entity class and arguments
   * @exception IllegalArgumentException whenever the implied constructor
   * does not exist or is not public
   */
  private <E extends AbstractEntity> Constructor<E> getConstructor(
    Class<E> entityClass,
    Object... arguments)
  {
    Class[] argumentTypes = getArgumentTypes(arguments);
    try {
      return entityClass.getConstructor(argumentTypes);
    }
    catch (SecurityException e) {
      throw new IllegalArgumentException(e);
    }
    catch (NoSuchMethodException e) {
      throw new IllegalArgumentException(e);
    }
  }

  /**
   * Return an array of types that correspond to the array of arguments.
   *  
   * @param arguments the arguments to get the types for
   * @return an array of types that correspond to the array of arguments
   */
  private Class[] getArgumentTypes(Object [] arguments)
  {
    Class [] argumentTypes = new Class [arguments.length];
    for (int i = 0; i < arguments.length; i++) {
      Class argumentType = arguments[i].getClass();
      if (argumentType.equals(Boolean.class)) {
        argumentType = Boolean.TYPE;
      }
      argumentTypes[i] = argumentType;
    }
    return argumentTypes;
  }
  
  /**
   * Construct and return a new entity object.
   * 
   * @param <E> the entity type
   * @param constructor the constructor to invoke
   * @param constructorArguments the (possibly empty) list of arguments to
   * pass to the constructor
   * @return the newly constructed entity object
   */
  private <E extends AbstractEntity> E newInstance(
    Constructor<E> constructor,
    Object... constructorArguments)
  {
    try {
      return constructor.newInstance(constructorArguments);
    }
    catch (IllegalArgumentException e) {
      throw new IllegalArgumentException(e);
    }
    catch (InstantiationException e) {
      throw new IllegalArgumentException(e);
    }
    catch (IllegalAccessException e) {
      throw new IllegalArgumentException(e);
    }
    catch (InvocationTargetException e) {
      throw new IllegalArgumentException(e);
    }
  }
}
