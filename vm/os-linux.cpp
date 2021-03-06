#include "master.hpp"

namespace factor
{

/* Snarfed from SBCL linux-so.c. You must free() the result yourself. */
const char *vm_executable_path()
{
	char *path = new char[PATH_MAX + 1];

	int size = readlink("/proc/self/exe", path, PATH_MAX);
	if (size < 0)
	{
		fatal_error("Cannot read /proc/self/exe",0);
		return NULL;
	}
	else
	{
		path[size] = '\0';

		const char *ret = safe_strdup(path);
		delete[] path;
		return ret;
	}
}

#ifdef SYS_inotify_init

VM_C_API int inotify_init()
{
	return syscall(SYS_inotify_init);
}

VM_C_API int inotify_add_watch(int fd, const char *name, u32 mask)
{
	return syscall(SYS_inotify_add_watch, fd, name, mask);
}

VM_C_API int inotify_rm_watch(int fd, u32 wd)
{
	return syscall(SYS_inotify_rm_watch, fd, wd);
}

#else

VM_C_API int inotify_init()
{
	VM_PTR->not_implemented_error();
	return -1;
}

VM_C_API int inotify_add_watch(int fd, const char *name, u32 mask)
{
	VM_PTR->not_implemented_error();
	return -1;
}

VM_C_API int inotify_rm_watch(int fd, u32 wd)
{
	VM_PTR->not_implemented_error();
	return -1;
}

#endif

}
