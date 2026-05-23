import Image from "next/image";
import Link from "next/link";

export function Header() {
	return (
		<header className="sticky left-0 top-0 z-40 w-full border-b border-border/50 bg-background py-4">
			<div className="mx-auto flex min-h-8 w-[95vw] max-w-screen-2xl items-center justify-between">
				<Link href="/" aria-label="Go to home">
					<Image
						src="/title.svg"
						alt="Superset"
						width={150}
						height={25}
						priority
					/>
				</Link>
			</div>
		</header>
	);
}
