//
//  ADCircularBuffer.c
//  Firmata-ObjC
//
//  Created by fiore on 29/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include "ADCircularBuffer.h"


void ADCircularBufferInit(ADCircularBuffer *cb, int size) {
    cb->size  = size + 1; /* include empty elem */
    cb->start = 0;
    cb->end   = 0;
    cb->elems = (ElemType *)calloc(cb->size, sizeof(ElemType));
}

void ADCircularBufferFree(ADCircularBuffer *cb) {
    free(cb->elems); /* OK if null */ }

int ADCircularBufferIsFull(ADCircularBuffer *cb) {
    return (cb->end + 1) % cb->size == cb->start; }

int ADCircularBufferIsEmpty(ADCircularBuffer *cb) {
    return cb->end == cb->start; }

/* Write an element, overwriting oldest element if buffer is full. App can
 choose to avoid the overwrite by checking cbIsFull(). */
void ADCircularBufferWrite(ADCircularBuffer *cb, ElemType *elem) {
    cb->elems[cb->end] = *elem;
    cb->end = (cb->end + 1) % cb->size;
    if (cb->end == cb->start)
        cb->start = (cb->start + 1) % cb->size; /* full, overwrite */
}

/* Read oldest element. App must ensure !cbIsEmpty() first. */
void ADCircularBufferRead(ADCircularBuffer *cb, ElemType *elem) {
    *elem = cb->elems[cb->start];
    cb->start = (cb->start + 1) % cb->size;
}