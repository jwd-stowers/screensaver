// $HeadURL$
// $Id$
//
// Copyright © 2006, 2010, 2011, 2012 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.util;

/**
 * A 3-tuple.
 *
 * @author <a mailto="john_sullivan@hms.harvard.edu">John Sullivan</a>
 */
public class Triple<F,S,T>
{

  private F _first;
  private S _second;
  private T _third;
  
  /**
   * Construct a new <code>Triple</code> object.
   * @param first the first element of the triple
   * @param second the second element of the triple
   * @param third the third element of the triple
   */
  public Triple(F first, S second, T third)
  {
    _first = first;
    _second = second;
    _third = third;
  }

  public static <F, S, T> Triple<F, S, T> newTriple(F first, S second, T third) 
  {
    return new Triple<F, S, T>(first, second, third);
  }

  /**
   * Get the first element of the triple.
   * @return the first element of the triple
   */
  public F getFirst()
  {
    return _first;
  }

  /**
   * Set the first element of the triple.
   * @param first the first element of the triple
   */
  public void setFirst(F first)
  {
    _first = first;
  }

  /**
   * Get the second element of the triple.
   * @return the second element of the triple
   */
  public S getSecond()
  {
    return _second;
  }

  /**
   * Set the second element of the triple.
   * @param second the second element of the triple
   */
  public void setSecond(S second)
  {
    _second = second;
  }

  /**
   * Set the third element of the triple.
   * @param third the third element of the triple
   */
  public void setThird(T third)
  {
    _third = third;
  }

  /**
   * Get the third element of the triple.
   * @return the third element of the triple
   */
  public T getThird()
  {
    return _third;
  }

  @Override
  public int hashCode()
  {
    final int PRIME1 = 2718;
    final int PRIME2 = 31;
    return PRIME1 * getFirst().hashCode() + PRIME2 * getSecond().hashCode() + getThird().hashCode();
  }

  @Override
  public boolean equals(Object object)
  {
    if (this == object) {
      return true;
    }
    if (! (object instanceof Triple)) {
      return false;
    }
    final Triple that = (Triple) object;
    return
      getFirst().equals(that.getFirst()) &&
      getSecond().equals(that.getSecond()) &&
      getThird().equals(that.getThird());
  }
}
