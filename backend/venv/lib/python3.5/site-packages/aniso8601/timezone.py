# -*- coding: utf-8 -*-

# Copyright (c) 2016, Brandon Nielsen
# All rights reserved.
#
# This software may be modified and distributed under the terms
# of the BSD license.  See the LICENSE file for details.

import datetime

def parse_timezone(tzstr):
    #tzstr can be ±hh:mm, ±hhmm, ±hh, the Z case is handled elsewhere

    tzstrlen = len(tzstr)

    if tzstrlen == 6:
        #±hh:mm
        tzhour = int(tzstr[1:3])
        tzminute = int(tzstr[4:6])

        if tzstr[0] == '+':
            return build_utcoffset(tzstr, datetime.timedelta(hours=tzhour, minutes=tzminute))
        else:
            if tzhour == 0 and tzminute == 0:
                raise ValueError('Negative ISO 8601 time offset cannot be 0.')
            else:
                return build_utcoffset(tzstr, -datetime.timedelta(hours=tzhour, minutes=tzminute))
    elif tzstrlen == 5:
        #±hhmm
        tzhour = int(tzstr[1:3])
        tzminute = int(tzstr[3:5])

        if tzstr[0] == '+':
            return build_utcoffset(tzstr, datetime.timedelta(hours=tzhour, minutes=tzminute))
        else:
            if tzhour == 0 and tzminute == 0:
                raise ValueError('Negative ISO 8601 time offset cannot be 0.')
            else:
                return build_utcoffset(tzstr, -datetime.timedelta(hours=tzhour, minutes=tzminute))
    elif tzstrlen == 3:
        #±hh
        tzhour = int(tzstr[1:3])

        if tzstr[0] == '+':
            return build_utcoffset(tzstr, datetime.timedelta(hours=tzhour))
        else:
            if tzhour == 0:
                raise ValueError('Negative ISO 8601 time offset cannot be 0.')
            else:
                return build_utcoffset(tzstr, -datetime.timedelta(hours=tzhour))
    else:
        raise ValueError('String is not a valid ISO 8601 time offset.')

def build_utcoffset(name, utcdelta):
    #We build an offset in this manner since the
    #tzinfo class must have an init that can
    #"method that can be called with no arguments"

    returnoffset = UTCOffset()

    returnoffset.setname(name)
    returnoffset.setutcdelta(utcdelta)

    return returnoffset

class UTCOffset(datetime.tzinfo):
    def __repr__(self):
        if self._utcdelta >= datetime.timedelta(hours=0):
            return '+{0} UTC'.format(self._utcdelta)
        else:
            #From the docs:
            #String representations of timedelta objects are normalized
            #similarly to their internal representation. This leads to
            #somewhat unusual results for negative timedeltas.
            #
            #Clean this up for printing purposes
            correctedDays = abs(self._utcdelta.days + 1) #Negative deltas start at -1 day

            deltaSeconds = (24 * 60 * 60) - self._utcdelta.seconds #Negative deltas have a positive seconds

            days, remainder = divmod(deltaSeconds, 24 * 60 * 60) #(24 hours / day) * (60 minutes / hour) * (60 seconds / hour)
            hours, remainder = divmod(remainder, 1 * 60 * 60) #(1 hour) * (60 minutes / hour) * (60 seconds / hour)
            minutes, seconds = divmod(remainder, 1 * 60) #(1 minute) * (60 seconds / minute)

            #Add any remaining days to the correctedDays count
            correctedDays += days

            if correctedDays == 0:
                return '-{0}:{1:02}:{2:02} UTC'.format(hours, minutes, seconds)
            else:
                if correctedDays == 1:
                    return '-1 day, {0}:{1:02}:{2:02} UTC'.format(hours, minutes, seconds)
                else:
                    return '-{0} days, {1}:{2:02}:{3:02} UTC'.format(correctedDays, hours, minutes, seconds)

    def setname(self, name):
        self._name = name

    def setutcdelta(self, utcdelta):
        self._utcdelta = utcdelta

    def utcoffset(self, dt):
        return self._utcdelta

    def tzname(self, dt):
        return self._name

    def dst(self, dt):
        #ISO 8601 specifies offsets should be different if DST is required,
        #instead of allowing for a DST to be specified
        # https://docs.python.org/2/library/datetime.html#datetime.tzinfo.dst
        return datetime.timedelta(0)
