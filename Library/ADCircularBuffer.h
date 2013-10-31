//
//  ADCircularBuffer.h
//  Firmata-ObjC
//
//  Created by fiore on 29/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#ifndef Firmata_ObjC_ADCircularBuffer_h
#define Firmata_ObjC_ADCircularBuffer_h

/** Straight from Wikipedia http://en.wikipedia.org/wiki/Circular_buffer **/


/* Opaque buffer element type.  This would be defined by the application. */
typedef struct { uint8_t value; } ElemType;

/* Circular buffer object */
typedef struct {
    int         size;   /* maximum number of elements           */
    int         start;  /* index of oldest element              */
    int         end;    /* index at which to write new element  */
    ElemType   *elems;  /* vector of elements                   */
} ADCircularBuffer;

// Init buffer

void ADCircularBufferInit(ADCircularBuffer *cb, int size);


void ADCircularBufferFree(ADCircularBuffer *cb) ;

int ADCircularBufferIsFull(ADCircularBuffer *cb) ;

int ADCircularBufferIsEmpty(ADCircularBuffer *cb) ;
/* Write an element, overwriting oldest element if buffer is full. App can
 choose to avoid the overwrite by checking cbIsFull(). */
void ADCircularBufferWrite(ADCircularBuffer *cb, ElemType *elem);
/* Read oldest element. App must ensure !cbIsEmpty() first. */
void ADCircularBufferRead(ADCircularBuffer *cb, ElemType *elem);

#endif
