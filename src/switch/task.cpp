/*
	Copyright (C) 2009-2015  DeSmuME team

	This file is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 2 of the License, or
	(at your option) any later version.

	This file is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with the this software.  If not, see <http://www.gnu.org/licenses/>.
*/
#include <switch.h>
#include <stdio.h>

#include "../utils/task.h"

class Task::Impl {
private:
	static int _numTasks;
	Thread _thread;
	bool _isThreadRunning;
	
public:
	Impl();
	~Impl();

	void start(bool spinlock);
	void execute(const TWork &work, void *param);
	void* finish();
	void shutdown();

	Mutex   mutex;
	CondVar condWork;

	TWork workFunc;
	void *workFuncParam;
	void *ret;
	bool exitThread;
};

static void taskProc(void *arg)
{
	Task::Impl *ctx = (Task::Impl *)arg;
	
	while(!ctx->exitThread)
	{
		while (ctx->workFunc == NULL && !ctx->exitThread)
		{
			condvarWait(&ctx->condWork);
		}

		if (ctx->workFunc != NULL)
			ctx->ret = ctx->workFunc(ctx->workFuncParam);
		else
			ctx->ret = NULL;

		ctx->workFunc = NULL;

		mutexUnlock(&ctx->mutex);
	}

}

int Task::Impl::_numTasks = 0;

Task::Impl::Impl()
{
	_isThreadRunning = false;
	workFunc = NULL;
	workFuncParam = NULL;
	ret = NULL;
	exitThread = false;

	condvarInit(&condWork, &mutex);
}

Task::Impl::~Impl()
{
	shutdown();
}

void Task::Impl::start(bool spinlock)
{
	if (this->_isThreadRunning) {
		return;
	}

	this->workFunc = NULL;
	this->workFuncParam = NULL;
	this->ret = NULL;
	this->exitThread = false;
	
	Result res = threadCreate( &_thread, &taskProc, this, 0x80000, 0x20, _numTasks++);

	if (R_FAILED(res))
	{
		printf("Failed to create thread!\n");
	}

	threadStart( &_thread);

	this->_isThreadRunning = true;

}

void Task::Impl::execute(const TWork &work, void *param)
{
	mutexLock(&this->mutex);

	if (work == NULL || !this->_isThreadRunning) {
		return;
	}

	this->workFunc = work;
	this->workFuncParam = param;

	condvarWakeOne(&this->condWork);

	mutexUnlock(&this->mutex);
}

void* Task::Impl::finish()
{
	mutexLock(&this->mutex);

	void *returnValue = NULL;

	if (!this->_isThreadRunning)
	{
		return returnValue;
	}

	returnValue = this->ret;

	mutexUnlock(&this->mutex);

	return returnValue;
}

void Task::Impl::shutdown()
{

	if (!this->_isThreadRunning) {
		return;
	}

	mutexLock(&this->mutex);

	this->workFunc = NULL;
	this->exitThread = true;
	
	condvarWakeOne(&this->condWork);

	mutexUnlock(&this->mutex);

	threadWaitForExit(&_thread);

	this->_isThreadRunning = false;
}

void Task::start(bool spinlock) { impl->start(spinlock); }
void Task::shutdown() { impl->shutdown(); }
Task::Task() : impl(new Task::Impl()) {}
Task::~Task() { delete impl; }
void Task::execute(const TWork &work, void* param) { impl->execute(work,param); }
void* Task::finish() { return impl->finish(); }

