import { Avatar } from "@superset/ui/atoms/Avatar";
import {
	DropdownMenu,
	DropdownMenuContent,
	DropdownMenuItem,
	DropdownMenuTrigger,
} from "@superset/ui/dropdown-menu";
import { useNavigate } from "@tanstack/react-router";
import { HiChevronUpDown, HiOutlineCog6Tooth } from "react-icons/hi2";
import { HotkeyMenuShortcut } from "renderer/components/HotkeyMenuShortcut";

// Single-user fork: there's only one org and no sign-out. This dropdown is
// kept as a thin settings affordance to preserve the topbar layout.
export function OrganizationDropdown({
	variant = "topbar",
}: {
	variant?: "topbar" | "expanded" | "collapsed";
}) {
	const navigate = useNavigate();

	const triggerButton =
		variant === "collapsed" ? (
			<button
				type="button"
				className="flex size-8 items-center justify-center rounded-md transition-colors text-muted-foreground hover:bg-accent/50 hover:text-foreground"
				aria-label="Open settings"
			>
				<Avatar size="xs" fullName="Local" className="rounded size-4" />
			</button>
		) : variant === "expanded" ? (
			<button
				type="button"
				className="group flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-sm font-medium text-muted-foreground transition-colors hover:bg-accent/50 hover:text-foreground min-w-0"
				aria-label="Open settings"
			>
				<Avatar
					size="xs"
					fullName="Local"
					className="rounded size-4 shrink-0"
				/>
				<span className="truncate">Local</span>
				<HiChevronUpDown className="ml-auto h-3.5 w-3.5 text-muted-foreground shrink-0" />
			</button>
		) : (
			<button
				type="button"
				className="group no-drag flex items-center gap-1.5 h-6 px-1.5 rounded border border-border/60 bg-secondary/50 hover:bg-secondary hover:border-border transition-all duration-150 ease-out focus:outline-none focus:ring-1 focus:ring-ring"
				aria-label="Open settings"
			>
				<Avatar size="xs" fullName="Local" className="rounded size-4" />
				<span className="text-xs font-medium truncate max-w-32">Local</span>
				<HiChevronUpDown className="h-3.5 w-3.5 text-muted-foreground shrink-0" />
			</button>
		);

	return (
		<DropdownMenu>
			<DropdownMenuTrigger asChild>{triggerButton}</DropdownMenuTrigger>
			<DropdownMenuContent
				align={variant === "topbar" ? "end" : "start"}
				className={
					variant === "expanded"
						? "w-[var(--radix-dropdown-menu-trigger-width)] min-w-56"
						: "w-56"
				}
			>
				<DropdownMenuItem
					onSelect={() => navigate({ to: "/settings/account" })}
				>
					<HiOutlineCog6Tooth className="h-4 w-4" />
					<span>Settings</span>
					<HotkeyMenuShortcut hotkeyId="OPEN_SETTINGS" />
				</DropdownMenuItem>
			</DropdownMenuContent>
		</DropdownMenu>
	);
}
